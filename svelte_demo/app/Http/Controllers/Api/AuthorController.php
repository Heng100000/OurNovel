<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreAuthorRequest;
use App\Http\Requests\Api\UpdateAuthorRequest;
use App\Http\Resources\Api\AuthorResource;
use App\Models\Author;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: "Author",
    required: ["id", "name"],
    properties: [
        new OA\Property(property: "id", type: "integer", example: 1),
        new OA\Property(property: "name", type: "string", example: "J.K. Rowling"),
        new OA\Property(property: "bio", type: "string", nullable: true),
        new OA\Property(property: "profile_image", type: "string", nullable: true),
        new OA\Property(property: "created_at", type: "string", format: "date-time"),
        new OA\Property(property: "updated_at", type: "string", format: "date-time")
    ]
)]
class AuthorController extends Controller
{
    #[OA\Get(
        path: "/api/authors",
        summary: "List all authors",
        tags: ["Authors"]
    )]
    #[OA\Response(
        response: 200,
        description: "A list of authors",
        content: new OA\JsonContent(type: "array", items: new OA\Items(ref: "#/components/schemas/Author"))
    )]
    public function index(): AnonymousResourceCollection
    {
        return AuthorResource::collection(Author::all());
    }

    #[OA\Post(
        path: "/api/authors",
        summary: "Create a new author",
        tags: ["Authors"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["name"],
            properties: [
                new OA\Property(property: "name", type: "string", example: "J.K. Rowling"),
                new OA\Property(property: "bio", type: "string", example: "British author..."),
                new OA\Property(property: "profile_image", type: "string", nullable: true)
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Author created successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Author")
    )]
    public function store(StoreAuthorRequest $request): JsonResponse
    {
        $author = Author::create($request->validated());
        return (new AuthorResource($author))
            ->response()
            ->setStatusCode(201);
    }

    #[OA\Get(
        path: "/api/authors/{id}",
        summary: "Get a specific author",
        tags: ["Authors"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Author details",
        content: new OA\JsonContent(ref: "#/components/schemas/Author")
    )]
    public function show(Author $author): AuthorResource
    {
        return new AuthorResource($author);
    }

    #[OA\Put(
        path: "/api/authors/{id}",
        summary: "Update an existing author",
        tags: ["Authors"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "name", type: "string", example: "Joanne Rowling"),
                new OA\Property(property: "bio", type: "string"),
                new OA\Property(property: "profile_image", type: "string", nullable: true)
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Author updated successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Author")
    )]
    public function update(UpdateAuthorRequest $request, Author $author): AuthorResource
    {
        $author->update($request->validated());
        return new AuthorResource($author);
    }

    #[OA\Delete(
        path: "/api/authors/{id}",
        summary: "Delete an author",
        tags: ["Authors"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(response: 204, description: "Author deleted successfully")]
    public function destroy(Author $author): JsonResponse
    {
        $author->delete();
        return response()->json(null, 204);
    }
}


