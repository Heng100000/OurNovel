<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Services\TelegramService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InvoiceTelegramController extends Controller
{
    public function __construct(private readonly TelegramService $telegram) {}

    /**
     * Generate and send the invoice PDF to the user's linked Telegram account.
     *
     * Called when the user scans the invoice QR code (or taps the Telegram send button).
     * The route is public (no auth) so a QR scan from any Telegram scanner works —
     * but the invoice is scoped to the owner's chat_id.
     *
     * Query params:
     *   ?color=RRGGBB  — user-chosen accent colour from the Flutter app
     */
    public function send(Request $request, string $invoiceNo): JsonResponse
    {
        // Find invoice by invoice_no (encoded in the QR code)
        $invoice = Invoice::where('invoice_no', $invoiceNo)
            ->with(['order.user', 'order.items.book', 'order.deliveryCompany'])
            ->firstOrFail();

        $user = $invoice->order?->user;

        if (! $user) {
            return response()->json(['message' => 'Invoice user not found.'], 404);
        }

        if (! $user->telegram_chat_id) {
            return response()->json([
                'message' => 'No Telegram account linked. Please link your Telegram first.',
                'linked' => false,
            ], 422);
        }

        // Read user-chosen accent colour (sent as hex RRGGBB from Flutter)
        $colorHex = ltrim($request->query('color', '2D3436'), '#');
        if (! preg_match('/^[0-9a-fA-F]{6}$/', $colorHex)) {
            $colorHex = '2D3436';
        }

        // Generate PDF bytes using the user's accent colour
        $pdfBytes = $this->generatePdfBytes($invoice, $colorHex);

        // Send the PDF document via Telegram
        $sent = $this->telegram->sendDocument(
            chatId: $user->telegram_chat_id,
            fileContents: $pdfBytes,
            filename: "invoice-{$invoice->invoice_no}.pdf",
            caption: $this->buildCaption($invoice),
        );

        if ($sent) {
            return response()->json([
                'message' => 'Invoice PDF sent to your Telegram successfully!',
                'sent' => true,
            ]);
        }

        return response()->json([
            'message' => 'Failed to send invoice to Telegram. Please try again.',
            'sent' => false,
        ], 500);
    }

    private function buildCaption(Invoice $invoice): string
    {
        $order = $invoice->order;
        $user = $order?->user;

        return "📄 <b>Invoice {$invoice->invoice_no}</b>\n\n".
            '<b>Customer:</b> '.($user?->name ?? 'Guest')."\n".
            "<b>Date:</b> {$invoice->created_at->format('d/m/Y')}\n".
            "────────────────\n".
            '<b>Grand Total:</b> $'.number_format((float) $invoice->grand_total, 2)."\n".
            "────────────────\n".
            '🇰🇭 <i>Thank you for your business!</i>';
    }

    private function generatePdfBytes(Invoice $invoice, string $colorHex = '2D3436'): string
    {
        $order = $invoice->order;
        $items = $order?->items ?? collect();
        $user = $order?->user;

        // ── Embed logo as base64 if available ──
        $logoHtml = '';
        $logoPath = public_path('images/logo_full.png');
        if (file_exists($logoPath)) {
            $logoBase64 = base64_encode(file_get_contents($logoPath));
            $logoMime = 'image/png';

            // Determine whether accent is light or dark to choose logo filter
            // Parse the R, G, B channels and compute relative luminance
            $r = hexdec(substr($colorHex, 0, 2));
            $g = hexdec(substr($colorHex, 2, 2));
            $b = hexdec(substr($colorHex, 4, 2));
            $luminance = (0.299 * $r + 0.587 * $g + 0.114 * $b) / 255;

            // Light accent → logo should be dark (no filter); dark accent → logo should be white (invert)
            $logoFilter = $luminance > 0.5
                ? 'filter: brightness(0);'          // makes PNG dark/black
                : 'filter: brightness(0) invert(1);'; // makes PNG white

            $logoHtml = "<img src='data:{$logoMime};base64,{$logoBase64}' style='height:40px;{$logoFilter}vertical-align:middle;'>";
        } else {
            $logoHtml = "<span style='font-size:18px;font-weight:bold;letter-spacing:1px;'>OURNOVEL</span>";
        }

        $itemsHtml = '';
        $sl = 1;
        foreach ($items as $item) {
            $title = e($item->book?->title ?? 'Item');
            $qty = $item->quantity;
            $price = number_format((float) $item->unit_price, 2);
            $total = number_format((float) ($item->unit_price * $item->quantity), 2);
            $rowBg = ($sl % 2 === 0) ? "background:#f9f9f9;" : '';
            $itemsHtml .= "
            <tr style='{$rowBg}'>
                <td style='padding:10px 32px;border-bottom:1px solid #eee;'>{$sl}</td>
                <td style='padding:10px 8px;border-bottom:1px solid #eee;'>{$title}</td>
                <td style='padding:10px 8px;border-bottom:1px solid #eee;text-align:center;'>\${$price}</td>
                <td style='padding:10px 8px;border-bottom:1px solid #eee;text-align:center;'>{$qty}</td>
                <td style='padding:10px 32px;border-bottom:1px solid #eee;text-align:right;font-weight:bold;'>\${$total}</td>
            </tr>";
            $sl++;
        }

        $subTotal = number_format((float) $invoice->sub_total, 2);
        $tax = number_format((float) $invoice->tax_amount, 2);
        $shippingFee = number_format((float) $invoice->shipping_fee, 2);
        $grandTotal = number_format((float) $invoice->grand_total, 2);
        $customerName = e($user?->name ?? 'Guest');
        $invoiceNo = e($invoice->invoice_no);
        $date = $invoice->created_at->format('d / m / Y');

        // ── Embed delivery logo as base64 if available ──
        $deliveryLogoHtml = '';
        if ($order && $order->deliveryCompany && $order->deliveryCompany->logo_path) {
            $deliveryLogoPath = storage_path('app/public/' . $order->deliveryCompany->logo_path);
            if (file_exists($deliveryLogoPath)) {
                $dLogoBase64 = base64_encode(file_get_contents($deliveryLogoPath));
                $deliveryLogoHtml = "<img src='data:image/png;base64,{$dLogoBase64}' style='height:24px;vertical-align:middle;margin-right:8px;'>";
            }
        }

        // All colour references use the user-chosen $colorHex
        $html = "<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<style>
  body { font-family: Arial, sans-serif; margin: 0; padding: 0; font-size: 13px; }
</style>
</head>
<body>

<table width='100%' style='background:#{$colorHex};color:#fff;padding:0;'><tr>
  <td style='padding:20px 32px;vertical-align:middle;'>{$logoHtml}</td>
  <td style='padding:20px 32px;text-align:right;font-size:28px;font-weight:bold;letter-spacing:4px;'>INVOICE</td>
</tr></table>

<table width='100%' style='background:#f5f5f5;'><tr>
  <td style='padding:20px 32px;vertical-align:top;'>
    <div style='font-size:10px;font-weight:bold;color:#{$colorHex};text-transform:uppercase;letter-spacing:1px;margin-bottom:6px;'>Invoice To:</div>
    <div style='font-weight:bold;font-size:14px;'>{$customerName}</div>
    " . ($order && $order->deliveryCompany ? "
    <div style='font-size:10px;font-weight:bold;color:#{$colorHex};text-transform:uppercase;letter-spacing:1px;margin-top:12px;margin-bottom:6px;'>Shipped via:</div>
    <div style='font-weight:bold;font-size:12px;'>{$deliveryLogoHtml}".e($order->deliveryCompany->name)."</div>
    " : "") . "
  </td>
  <td style='padding:20px 32px;text-align:right;vertical-align:top;'>
    <div><span style='font-weight:bold;color:#{$colorHex};'>Invoice#</span> &nbsp; {$invoiceNo}</div>
    <div style='margin-top:4px;'><span style='font-weight:bold;'>Date:</span> &nbsp; {$date}</div>
  </td>
</tr></table>

<table width='100%' style='border-collapse:collapse;margin-top:16px;'>
  <tr style='background:#{$colorHex};color:#fff;'>
    <th style='padding:10px 32px;text-align:left;width:32px;'>SL.</th>
    <th style='padding:10px 8px;text-align:left;'>Item Description</th>
    <th style='padding:10px 8px;text-align:center;'>Price</th>
    <th style='padding:10px 8px;text-align:center;'>Qty.</th>
    <th style='padding:10px 32px;text-align:right;'>Total</th>
  </tr>
  {$itemsHtml}
</table>

<table width='100%' style='margin-top:24px;'>
<tr>
  <td style='padding:0 32px;vertical-align:bottom;'>
    <div style='font-weight:bold;color:#{$colorHex};'>Thank you for your business</div>
  </td>
  <td style='padding:0 32px;text-align:right;vertical-align:top;'>
    <div style='margin-bottom:4px;'><span style='color:#888;'>Sub Total:</span> &nbsp; <span>\${$subTotal}</span></div>
    <div style='margin-bottom:4px;'><span style='color:#888;'>Tax:</span> &nbsp; <span>{$tax}%</span></div>
    " . ((float) $invoice->shipping_fee > 0 ? "
    <div style='margin-bottom:4px;'><span style='color:#888;'>Shipping Fee:</span> &nbsp; <span>\${$shippingFee}</span></div>
    " : "") . "
    <hr style='border:none;border-top:1px solid #ddd;margin:8px 0;'>
    <div style='font-size:16px;font-weight:bold;'>
      <span>Total:</span> &nbsp; <span style='color:#{$colorHex};'>\${$grandTotal}</span>
    </div>
  </td>
</tr>
</table>

<div style='padding:24px 32px;text-align:right;margin-top:20px;'>
  <div style='display:inline-block;border-top:2px solid #{$colorHex};padding-top:4px;font-size:11px;color:#888;min-width:140px;text-align:center;'>
    Authorised Sign
  </div>
</div>

</body>
</html>";

        // Use Dompdf if available, otherwise send HTML (renderable as PDF in browser)
        if (class_exists(\Barryvdh\DomPDF\Facade\Pdf::class)) {
            return \Barryvdh\DomPDF\Facade\Pdf::loadHTML($html)->output();
        }

        return $html;
    }
}
