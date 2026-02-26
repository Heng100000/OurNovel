<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreCategoryRequest;
use App\Http\Requests\Api\UpdateCategoryRequest;
use App\Http\Resources\Api\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: "Category",
    required: ["id", "name"],
    properties: [
        new OA\Property(property: "id", type: "integer", example: 1),
        new OA\Property(property: "parent_id", type: "integer", nullable: true, example: null),
        new OA\Property(property: "name", type: "string", example: "Fiction"),
        new OA\Property(property: "created_at", type: "string", format: "date-time"),
        new OA\Property(property: "updated_at", type: "string", format: "date-time")
    ]
)]
class CategoryController extends Controller
{
    #[OA\Get(
        path: "/api/categories",
        summary: "List all categories",
        tags: ["Categories"]
    )]
    #[OA\Response(
        response: 200,
        description: "A list of categories",
        content: new OA\JsonContent(type: "array", items: new OA\Items(ref: "#/components/schemas/Category"))
    )]
    public function index(): AnonymousResourceCollection
    {
        $categories = Category::with(['parent', 'children'])->get();
        return CategoryResource::collection($categories);
    }

    #[OA\Post(
        path: "/api/categories",
        summary: "Create a new category",
        tags: ["Categories"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["name"],
            properties: [
                new OA\Property(property: "name", type: "string", example: "Fiction"),
                new OA\Property(property: "parent_id", type: "integer", nullable: true, example: null)
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Category created successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Category")
    )]
    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $category = Category::create($request->validated());
        return (new CategoryResource($category))
            ->response()
            ->setStatusCode(201);
    }

    #[OA\Get(
        path: "/api/categories/{id}",
        summary: "Get a specific category",
        tags: ["Categories"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Category details",
        content: new OA\JsonContent(ref: "#/components/schemas/Category")
    )]
    #[OA\Response(response: 404, description: "Category not found")]
    public function show(Category $category): CategoryResource
    {
        return new CategoryResource($category->load(['parent', 'children']));
    }

    #[OA\Put(
        path: "/api/categories/{id}",
        summary: "Update an existing category",
        tags: ["Categories"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "name", type: "string", example: "Science Fiction"),
                new OA\Property(property: "parent_id", type: "integer", nullable: true)
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Category updated successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Category")
    )]
    public function update(UpdateCategoryRequest $request, Category $category): CategoryResource
    {
        $category->update($request->validated());
        return new CategoryResource($category);
    }

    #[OA\Delete(
        path: "/api/categories/{id}",
        summary: "Delete a category",
        tags: ["Categories"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(response: 204, description: "Category deleted successfully")]
    #[OA\Response(response: 404, description: "Category not found")]
    public function destroy(Category $category): JsonResponse
    {
        $category->delete();
        return response()->json(null, 204);
    }
}

/**
 * @OA\Schema(
 *     schema="Category",
 *     required={"id", "name"},
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="parent_id", type="integer", nullable=true, example=null),
 *     @OA\Property(property="name", type="string", example="Fiction"),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 */
