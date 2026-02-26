<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'method' => ['sometimes', 'string', 'in:aba,bakong,aceleda,cash,card'],
            'amount' => ['sometimes', 'numeric', 'min:0.01'],
            'status' => ['sometimes', 'string', 'in:pending,paid,failed,refunded'],
            'txn_id' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'method.in' => 'Payment method must be one of: aba, bakong, aceleda, cash, card.',
            'status.in' => 'Status must be one of: pending, paid, failed, refunded.',
            'amount.min' => 'Amount must be at least $0.01.',
        ];
    }
}
