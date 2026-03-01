import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../theme/theme_service.dart';
import '../../../../l10n/language_service.dart';
import '../../data/invoice_model.dart';

class InvoiceDetailPage extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  Color _accentColor = AppColors.primary;
  bool _isGeneratingPdf = false;
  bool _isSendingTelegram = false;
  Uint8List? _logoBytes;

  static const String _colorPrefKey = 'invoice_accent_color';
  static const String _logoAssetPath = 'assets/images/logo_full.png';

  @override
  void initState() {
    super.initState();
    _loadSavedColor();
    _loadLogoBytes();
  }

  Future<void> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load(_logoAssetPath);
      setState(() => _logoBytes = data.buffer.asUint8List());
    } catch (_) {
      // Logo not found, will fall back to icon
    }
  }

  Future<void> _loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_colorPrefKey);
    if (saved != null) {
      setState(() => _accentColor = Color(saved));
    }
  }

  String get _telegramTriggerUrl {
    final hex = _accentColor.value.toRadixString(16).padLeft(8, '0').substring(2); // RRGGBB
    return '${ApiConstants.baseUrl}/invoices/send-telegram/${widget.invoice.invoiceNo}?color=$hex';
  }

  Future<void> _sendToTelegram() async {
    setState(() => _isSendingTelegram = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(_telegramTriggerUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer \$token',
        },
      ).timeout(const Duration(seconds: 20));

      final body = json.decode(response.body);
      final message = body['message'] ?? '';

      if (mounted) {
        if (response.statusCode == 200) {
          _showSnack('✅ \$message', Colors.green);
        } else if (response.statusCode == 422) {
          _showSnack('⚠️ \$message', Colors.orange);
        } else {
          _showSnack('❌ \$message', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('❌ Connection error: \$e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSendingTelegram = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveColor(Color c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorPrefKey, c.value);
  }

  void _openColorPicker() {
    Color temp = _accentColor;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('Invoice Color Theme', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 20),
                  // Quick preset colors
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Color(0xFF2D3436), // dark charcoal
                      const Color(0xFF1E3A1E), // dark green
                      const Color(0xFF1A237E), // navy blue
                      const Color(0xFF880E4F), // deep pink
                      const Color(0xFFBF360C), // deep orange
                      const Color(0xFF37474F), // blue grey
                      const Color(0xFF4A148C), // deep purple
                      const Color(0xFF006064), // teal
                      const Color(0xFF33691E), // light green
                      const Color(0xFFE65100), // orange
                    ].map((c) {
                      final isSelected = temp.value == c.value;
                      return GestureDetector(
                        onTap: () => setSheet(() => temp = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                            boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)] : [],
                          ),
                          child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Custom color wheel
                  HueRingPicker(
                    pickerColor: temp,
                    onColorChanged: (c) => setSheet(() => temp = c),
                    enableAlpha: false,
                    displayThumbColor: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _accentColor = temp);
                            _saveColor(temp);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: temp,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── PDF Generation ───────────────────────────────────────────────────────────

  /// Tint a PNG's pixels to [tintColor] using the same BlendMode.srcIn logic
  /// Flutter uses for Image.memory's colorBlendMode, so the PDF logo matches
  /// exactly what the user sees in the app interface.
  Future<Uint8List?> _tintImageBytes(Uint8List bytes, Color tintColor) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.mode(tintColor, BlendMode.srcIn);
      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final tinted = await picture.toImage(image.width, image.height);
      final byteData = await tinted.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null; // fall back to original bytes
    }
  }

  Future<Uint8List> _generatePdf() async {
    final doc = pw.Document();
    final invoice = widget.invoice;
    final items = invoice.orderItems;
    final accentPdf = PdfColor.fromInt(_accentColor.value);

    // Compute contrast color — same logic as Flutter header
    final brightness = ThemeData.estimateBrightnessForColor(_accentColor);
    final logoTint = brightness == Brightness.light ? Colors.black87 : Colors.white;
    final onAccentPdf = brightness == Brightness.light ? PdfColors.black : PdfColors.white;

    // Tint logo bytes so PDF matches the app interface exactly
    Uint8List? tintedLogoBytes;
    if (_logoBytes != null) {
      tintedLogoBytes = await _tintImageBytes(_logoBytes!, logoTint);
    }

    // Fetch delivery logo bytes if present
    Uint8List? deliveryLogoBytes;
    if (invoice.deliveryLogoUrl != null) {
      try {
        final response = await http.get(Uri.parse(invoice.deliveryLogoUrl!));
        if (response.statusCode == 200) {
          deliveryLogoBytes = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Error fetching delivery logo for PDF: $e');
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Container(
                color: accentPdf,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (tintedLogoBytes != null)
                      pw.Image(
                        pw.MemoryImage(tintedLogoBytes),
                        height: 40,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('OURNOVEL', style: pw.TextStyle(color: onAccentPdf, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Your Digital Book Store', style: pw.TextStyle(color: onAccentPdf, fontSize: 10)),
                        ],
                      ),
                    pw.Text('INVOICE', style: pw.TextStyle(color: onAccentPdf, fontSize: 36, fontWeight: pw.FontWeight.bold, letterSpacing: 4)),
                  ],
                ),
              ),

              // ── Info Row ──
              pw.Container(
                color: PdfColor.fromHex('#F5F5F5'),
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentPdf)),
                        pw.SizedBox(height: 6),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        if (invoice.addressDetails.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(invoice.addressDetails, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                        if (invoice.addressCity.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(invoice.addressCity, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                        // Delivery company in PDF
                        if (invoice.deliveryCompany != null) ...[
                          pw.SizedBox(height: 10),
                          pw.Text('Shipped via:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentPdf)),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              if (deliveryLogoBytes != null)
                                pw.Container(
                                  width: 24,
                                  height: 24,
                                  margin: const pw.EdgeInsets.only(right: 6),
                                  child: pw.Image(pw.MemoryImage(deliveryLogoBytes), fit: pw.BoxFit.contain),
                                ),
                              pw.Text(
                                invoice.deliveryCompany!['name'] as String? ?? '',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pdfInfoRow('Invoice#', invoice.invoiceNo, accentPdf),
                        pw.SizedBox(height: 4),
                        _pdfInfoRow('Date:', DateFormat('dd / MM / yyyy').format(invoice.createdAt), accentPdf),
                        if (invoice.paymentMethod != null) ...[
                          pw.SizedBox(height: 4),
                          _pdfInfoRow('Payment:', invoice.paymentMethod!, accentPdf),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Items Table ──
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: accentPdf),
                      children: [
                        _pdfTableHeader('SL.'),
                        _pdfTableHeader('Item Description'),
                        _pdfTableHeader('Price'),
                        _pdfTableHeader('Qty.'),
                        _pdfTableHeader('Total', align: pw.TextAlign.right),
                      ],
                    ),
                    // Item rows
                    ...items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final book = item['book'] ?? {};
                      final price = double.tryParse(item['price'].toString()) ?? 0;
                      final total = double.tryParse(item['total_price'].toString()) ?? 0;
                      final qty = item['quantity'];
                      final isAlt = i % 2 == 1;
                      return pw.TableRow(
                        decoration: isAlt ? pw.BoxDecoration(color: PdfColor.fromHex('#F9F9F9')) : null,
                        children: [
                          _pdfTableCell('${i + 1}'),
                          _pdfTableCell(book['title'] ?? 'Item'),
                          _pdfTableCell('\$${price.toStringAsFixed(2)}'),
                          _pdfTableCell('$qty'),
                          _pdfTableCell('\$${total.toStringAsFixed(2)}', align: pw.TextAlign.right),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // ── Footer ──
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Thank you for your business', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: accentPdf)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pdfSummaryRow('Sub Total:', '\$${double.parse(invoice.subTotal).toStringAsFixed(2)}'),
                        _pdfSummaryRow('Tax:', '${double.parse(invoice.taxAmount).toStringAsFixed(2)}%'),
                        if (double.parse(invoice.shippingFee) > 0)
                          _pdfSummaryRow('Shipping Fee:', '\$${double.parse(invoice.shippingFee).toStringAsFixed(2)}'),
                        pw.Divider(),
                        _pdfSummaryRow('Total:', '\$${double.parse(invoice.grandTotal).toStringAsFixed(2)}', isBig: true, color: accentPdf),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 40),

              // Signature line
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.grey),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorised Sign', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfInfoRow(String label, String value, PdfColor accentPdf) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentPdf)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  pw.Widget _pdfTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
    );
  }

  pw.Widget _pdfTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 11)),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool isBig = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBig ? pw.FontWeight.bold : null, fontSize: isBig ? 14 : 11)),
          pw.SizedBox(width: 16),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isBig ? 16 : 11, color: color)),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generatePdf();
      await Printing.sharePdf(bytes: bytes, filename: 'invoice-${widget.invoice.invoiceNo}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF4F4F4);
        final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

        final invoice = widget.invoice;
        final items = invoice.orderItems;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: _accentColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              langService.translate('invoice_detail'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              // Color picker button
              IconButton(
                icon: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.palette_rounded, color: Colors.white, size: 14),
                ),
                onPressed: _openColorPicker,
                tooltip: 'Change color',
              ),
              // PDF download
              IconButton(
                icon: _isGeneratingPdf
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: Colors.white),
                onPressed: _isGeneratingPdf ? null : _downloadPdf,
                tooltip: 'Download PDF',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── Invoice Card ──
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        // ── Dark header ──
                        _buildInvoiceHeader(isDark),

                        // ── Info Row ──
                        _buildInfoSection(isDark, langService, invoice),

                        // ── Divider ──
                        Divider(height: 1, color: borderColor),

                        // ── Items Table ──
                        _buildItemsTable(items, isDark, langService),

                        // ── Summary ──
                        _buildSummarySection(isDark, langService, invoice),

                        // ── Thank you + QR ──
                        _buildFooterSection(isDark, invoice),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Action Buttons ──
                _buildActionButtons(isDark, langService),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Invoice Header ───────────────────────────────────────────────────────────

  Widget _buildInvoiceHeader(bool isDark) {
    // Compute a contrasting logo/text color based on the accent luminance
    final brightness = ThemeData.estimateBrightnessForColor(_accentColor);
    final onAccent = brightness == Brightness.light ? Colors.black87 : Colors.white;
    final onAccentMuted = brightness == Brightness.light
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.7);

    return Container(
      color: _accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand logo
          Row(
            children: [
              if (_logoBytes != null)
                Image.memory(
                  _logoBytes!,
                  height: 44,
                  fit: BoxFit.contain,
                  color: onAccent,
                  colorBlendMode: BlendMode.srcIn,
                )
              else
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: onAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: onAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OURNOVEL', style: TextStyle(color: onAccent, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                        Text('Your Digital Book Store', style: TextStyle(color: onAccentMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          // INVOICE title
          Text(
            'INVOICE',
            style: TextStyle(
              color: onAccent.withOpacity(0.95),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Section ─────────────────────────────────────────────────────────────

  Widget _buildInfoSection(bool isDark, LanguageService langService, InvoiceModel invoice) {
    final subtleText = isDark ? Colors.white38 : Colors.grey[600];
    final boldText = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9F9F9),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langService.translate('billing_to'),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: _accentColor, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(invoice.customerName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: boldText)),
                const SizedBox(height: 4),
                if (invoice.addressDetails.isNotEmpty)
                  Text(invoice.addressDetails, style: TextStyle(fontSize: 12, color: subtleText, height: 1.4)),
                if (invoice.addressCity.isNotEmpty)
                  Text(invoice.addressCity, style: TextStyle(fontSize: 12, color: subtleText)),
                if (invoice.customerPhone.isNotEmpty && invoice.customerPhone != 'N/A')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(invoice.customerPhone, style: TextStyle(fontSize: 12, color: subtleText)),
                  ),

                // ── Delivery company (if selected) ──
                if (invoice.deliveryCompany != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Shipped via',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: _accentColor, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (invoice.deliveryLogoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: invoice.deliveryLogoUrl!,
                            height: 32,
                            width: 32,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(Icons.local_shipping_outlined, size: 24, color: subtleText),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        invoice.deliveryCompany!['name'] as String? ?? '',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: boldText),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Invoice meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMetaRow('Invoice#', invoice.invoiceNo, boldText, subtleText),
              const SizedBox(height: 6),
              _buildMetaRow(langService.translate('issue_date'), DateFormat('dd / MM / yyyy').format(invoice.createdAt), boldText, subtleText),
              if (invoice.paymentMethod != null) ...[
                const SizedBox(height: 6),
                _buildMetaRow('Payment', invoice.paymentMethod!, boldText, subtleText),
              ],
              if (invoice.orderStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: invoice.orderStatus.toLowerCase() == 'completed' || invoice.orderStatus.toLowerCase() == 'paid'
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    invoice.orderStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: invoice.orderStatus.toLowerCase() == 'completed' || invoice.orderStatus.toLowerCase() == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color? boldText, Color? subtleText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label  ', style: TextStyle(fontSize: 11, color: subtleText, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: boldText)),
      ],
    );
  }

  // ─── Items Table ─────────────────────────────────────────────────────────────

  Widget _buildItemsTable(List<dynamic> items, bool isDark, LanguageService langService) {
    final headerBg = _accentColor;
    final altRowBg = isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF9F9F9);
    final boldText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtleText = isDark ? Colors.white60 : Colors.grey[700];

    return Column(
      children: [
        // Table header
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 32, child: Text('SL.', style: _tableHeaderStyle())),
              Expanded(flex: 4, child: Text(langService.translate('description'), style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text(langService.translate('price_label'), style: _tableHeaderStyle())),
              SizedBox(width: 36, child: Text(langService.translate('qty'), textAlign: TextAlign.center, style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text(langService.translate('subtotal'), textAlign: TextAlign.right, style: _tableHeaderStyle())),
            ],
          ),
        ),
        // Table rows
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(langService.translate('no_data'), style: TextStyle(color: subtleText))),
          )
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final book = item['book'] ?? {};
            final price = double.tryParse(item['price'].toString()) ?? 0;
            final total = double.tryParse(item['total_price'].toString()) ?? 0;
            final qty = item['quantity'];
            final isAlt = index % 2 == 1;

            return Container(
              color: isAlt ? altRowBg : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('${index + 1}', style: TextStyle(fontSize: 13, color: _accentColor, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      book['title'] ?? 'Item',
                      style: TextStyle(fontSize: 13, color: boldText, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: subtleText)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('$qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: subtleText)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '\$${total.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: boldText),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  TextStyle _tableHeaderStyle() => const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12);

  // ─── Summary Section ─────────────────────────────────────────────────────────

  Widget _buildSummarySection(bool isDark, LanguageService langService, InvoiceModel invoice) {
    final subtleText = isDark ? Colors.white38 : Colors.grey[600];
    final boldText = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    final subTotal = double.tryParse(invoice.subTotal) ?? 0;
    final tax = double.tryParse(invoice.taxAmount) ?? 0;
    final grandTotal = double.tryParse(invoice.grandTotal) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: thank you
          Expanded(
            child: Text(
              'Thank you for your business',
              style: TextStyle(fontWeight: FontWeight.w700, color: _accentColor, fontSize: 13),
            ),
          ),
          // Right: summary
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSummaryRow(langService.translate('subtotal'), '\$${subTotal.toStringAsFixed(2)}', subtleText, boldText),
              const SizedBox(height: 4),
              _buildSummaryRow(langService.translate('tax'), '${tax.toStringAsFixed(2)}%', subtleText, boldText),
              if (double.tryParse(invoice.shippingFee) != null && double.parse(invoice.shippingFee) > 0) ...[
                const SizedBox(height: 4),
                _buildSummaryRow('Shipping Fee', '\$${double.parse(invoice.shippingFee).toStringAsFixed(2)}', subtleText, boldText),
              ],
              const SizedBox(height: 8),
              SizedBox(width: 200, child: Divider(color: borderColor, height: 1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${langService.translate('grand_total')}:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: boldText)),
                  const SizedBox(width: 20),
                  Text(
                    '\$${grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: _accentColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color? subtleText, Color? boldText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 90, child: Text('$label:', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: subtleText))),
        const SizedBox(width: 16),
        SizedBox(width: 70, child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: boldText))),
      ],
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────────

  Widget _buildFooterSection(bool isDark, InvoiceModel invoice) {
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final subtleText = isDark ? Colors.white38 : Colors.grey[500];

    return Column(
      children: [
        Divider(height: 1, color: borderColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // QR Code — encodes the Telegram trigger URL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: QrImageView(
                      data: _telegramTriggerUrl,
                      version: QrVersions.auto,
                      size: 80,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _accentColor),
                      dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _accentColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.telegram_rounded, size: 12, color: subtleText),
                      const SizedBox(width: 4),
                      Text('Scan → send to Telegram', style: TextStyle(fontSize: 10, color: subtleText)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Signature
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(width: 140, height: 1, color: isDark ? Colors.white38 : Colors.grey.shade400),
                  const SizedBox(height: 4),
                  Text('Authorised Sign', style: TextStyle(fontSize: 11, color: subtleText)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isDark, LanguageService langService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Download PDF
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPdf ? null : _downloadPdf,
              icon: _isGeneratingPdf
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
              label: Text(
                _isGeneratingPdf ? 'Generating...' : langService.translate('download_invoice'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Telegram send button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2CA5E0).withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2CA5E0).withOpacity(0.5)),
            ),
            child: _isSendingTelegram
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF2CA5E0), strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.telegram_rounded, color: Color(0xFF2CA5E0)),
                    onPressed: _sendToTelegram,
                    padding: const EdgeInsets.all(14),
                    tooltip: 'Send invoice to Telegram',
                  ),
          ),
          const SizedBox(width: 12),
          // Change color
          Container(
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentColor.withOpacity(0.4)),
            ),
            child: IconButton(
              icon: Icon(Icons.palette_rounded, color: _accentColor),
              onPressed: _openColorPicker,
              padding: const EdgeInsets.all(14),
              tooltip: 'Change invoice color',
            ),
          ),
        ],
      ),
    );
  }
}
