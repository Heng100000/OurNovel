<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBookRequest extends FormRequest
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
            'book_id' => ['sometimes', 'exists:books,id'],
            'author_id' => ['sometimes', 'required', 'exists:authors,id'],
            'category_id' => ['sometimes', 'required', 'exists:categories,id'],
            'promotion_id' => ['sometimes', 'nullable', 'exists:promotions,id'],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'isbn' => ['sometimes', 'nullable', 'string', 'max:20'],
            'description' => ['sometimes', 'required', 'string'],
            'price' => ['sometimes', 'required', 'numeric', 'min:0'],
            'stock_qty' => ['sometimes', 'required', 'integer', 'min:0'],
            'condition' => ['sometimes', 'nullable', 'string', 'in:New,Popular'],
            'status' => ['sometimes', 'required', 'string', 'in:active,inactive,out_of_stock'],
            'video_url' => ['sometimes', 'nullable', 'url', 'max:255'],
            'images' => ['sometimes', 'nullable', 'array'],
            'images.*.image_url' => ['sometimes', 'required'], // Can be file or base64 string
            'images.*.is_primary' => ['sometimes', 'required', 'boolean'],
        ];
    }
}
