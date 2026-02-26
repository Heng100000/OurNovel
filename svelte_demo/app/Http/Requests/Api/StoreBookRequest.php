<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreBookRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'author_id' => ['required', 'exists:authors,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'promotion_id' => ['nullable', 'exists:promotions,id'],
            'title' => ['required', 'string', 'max:255'],
            'isbn' => ['nullable', 'string', 'max:20'],
            'description' => ['required', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'stock_qty' => ['required', 'integer', 'min:0'],
            'condition' => ['nullable', 'string', 'in:New,Popular'],
            'status' => ['required', 'string', 'in:active,inactive,out_of_stock'],
            'video_url' => ['nullable', 'url', 'max:255'],
            'images' => ['nullable', 'array'],
            'images.*.image_url' => ['required_with:images'], // Can be file or base64 string
            'images.*.is_primary' => ['required_with:images', 'boolean'],
        ];
    }
}
