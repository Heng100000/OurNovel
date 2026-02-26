<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StorePaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'order_id' => ['required', 'integer', 'exists:orders,id'],
            'method'   => ['required', 'string', 'in:aba,bakong,aceleda,cash,card'],
        ];
    }

    public function messages(): array
    {
        return [
            'order_id.exists' => 'The selected order does not exist.',
            'method.in'       => 'Payment method must be one of: aba, bakong, aceleda, cash, card.',
        ];
    }
}
