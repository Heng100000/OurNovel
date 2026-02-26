<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Http\Resources\InvoiceResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class InvoiceController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $invoices = Invoice::whereHas('order', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->with('order')->latest()->get();

        return InvoiceResource::collection($invoices);
    }

    public function show(Request $request, Invoice $invoice): InvoiceResource
    {
        if ($invoice->order->user_id !== $request->user()->id) {
            abort(403, 'Unauthorized access to this invoice.');
        }

        return new InvoiceResource($invoice->load('order'));
    }
}
