<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreReviewRequest;
use App\Http\Requests\Api\UpdateReviewRequest;
use App\Http\Resources\Api\ReviewResource;
use App\Models\Review;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: "Review",
    required: ["id", "book_id", "user_id", "rating"],
    properties: [
        new OA\Property(property: "id", type: "integer", example: 1),
        new OA\Property(property: "book_id", type: "integer", example: 1),
        new OA\Property(property: "user_id", type: "integer", nullable: true, example: 1, description: "Optional. Defaults to authenticated user if not provided."),
        new OA\Property(property: "rating", type: "integer", minimum: 1, maximum: 5, example: 5),
        new OA\Property(property: "comment", type: "string", example: "Great book!"),
        new OA\Property(property: "created_at", type: "string", format: "date-time"),
        new OA\Property(property: "updated_at", type: "string", format: "date-time")
    ]
)]
class ReviewController extends Controller
{
    #[OA\Get(
        path: "/api/reviews",
        summary: "List all reviews",
        tags: ["Reviews"]
    )]
    #[OA\Response(
        response: 200,
        description: "A list of reviews",
        content: new OA\JsonContent(type: "array", items: new OA\Items(ref: "#/components/schemas/Review"))
    )]
    public function index(): AnonymousResourceCollection
    {
        $reviews = Review::with(['book', 'user'])->latest()->get();
        return ReviewResource::collection($reviews);
    }

    #[OA\Post(
        path: "/api/reviews",
        summary: "Create a new review",
        tags: ["Reviews"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(ref: "#/components/schemas/Review")
    )]
    #[OA\Response(
        response: 201,
        description: "Review created successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Review")
    )]
    public function store(StoreReviewRequest $request): JsonResponse
    {
        $data = $request->validated();
        
        // Automatically set user_id if not provided and user is authenticated
        $userId = $data['user_id'] ?? (auth()->check() ? auth()->id() : null);
        
        if (!$userId) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $review = Review::updateOrCreate(
            ['book_id' => $data['book_id'], 'user_id' => $userId],
            ['rating' => $data['rating'], 'comment' => $data['comment'] ?? null]
        );

        return (new ReviewResource($review->load(['book', 'user'])))
            ->response()
            ->setStatusCode(201);
    }

    #[OA\Get(
        path: "/api/reviews/{id}",
        summary: "Get a specific review",
        tags: ["Reviews"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Review details",
        content: new OA\JsonContent(ref: "#/components/schemas/Review")
    )]
    public function show(Review $review): ReviewResource
    {
        return new ReviewResource($review->load(['book', 'user']));
    }

    #[OA\Put(
        path: "/api/reviews/{id}",
        summary: "Update an existing review",
        tags: ["Reviews"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Review updated successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Review")
    )]
    public function update(UpdateReviewRequest $request, Review $review): ReviewResource
    {
        $review->update($request->validated());

        return new ReviewResource($review->load(['book', 'user']));
    }

    #[OA\Delete(
        path: "/api/reviews/{id}",
        summary: "Delete a review",
        tags: ["Reviews"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(response: 204, description: "Review deleted successfully")]
    public function destroy(Review $review): JsonResponse
    {
        $review->delete();
        return response()->json(null, 204);
    }
}
