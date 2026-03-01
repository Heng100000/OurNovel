<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Http\Resources\InvoiceResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class InvoiceController extends Controller
{
    /**
     * Minimal relations for the invoice list — fast to load.
     * The detail page (show) loads everything via $fullRelations.
     */
    private array $listRelations = [
        'order.user',
        'order.address',
        'order.items.book',
        'order.deliveryCompany',
        'order.payment',
    ];

    private array $fullRelations = [
        'order.user',
        'order.address',
        'order.items.book.images',
        'order.deliveryCompany',
        'order.payment',
    ];

    public function index(Request $request): AnonymousResourceCollection
    {
        $invoices = Invoice::whereHas('order', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->with($this->listRelations)->latest()->get();

        return InvoiceResource::collection($invoices);
    }

    public function show(Request $request, Invoice $invoice): InvoiceResource
    {
        // Use loadMissing to load full relations without re-loading already loaded parents
        $invoice->loadMissing($this->fullRelations);

        if ($invoice->order->user_id !== $request->user()->id) {
            abort(403, 'Unauthorized access to this invoice.');
        }

        return new InvoiceResource($invoice);
    }
}
