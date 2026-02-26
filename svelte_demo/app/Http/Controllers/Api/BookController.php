<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreBookRequest;
use App\Http\Requests\Api\UpdateBookRequest;
use App\Http\Resources\Api\BookResource;
use App\Models\Book;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: "Book",
    required: ["id", "title", "price"],
    properties: [
        new OA\Property(property: "id", type: "integer", example: 1),
        new OA\Property(property: "title", type: "string", example: "The Great Gatsby"),
        new OA\Property(property: "isbn", type: "string", nullable: true),
        new OA\Property(property: "price", type: "number", format: "float", example: 19.99),
        new OA\Property(property: "stock_qty", type: "integer", example: 10),
        new OA\Property(property: "condition", type: "string", example: "new"),
        new OA\Property(property: "status", type: "string", example: "active"),
        new OA\Property(
            property: "images",
            type: "array",
            items: new OA\Items(
                properties: [
                    new OA\Property(property: "image_url", type: "string"),
                    new OA\Property(property: "is_primary", type: "boolean")
                ]
            )
        ),
        new OA\Property(property: "created_at", type: "string", format: "date-time"),
        new OA\Property(property: "updated_at", type: "string", format: "date-time")
    ]
) ]
class BookController extends Controller
{
    #[OA\Get(
        path: "/api/books",
        summary: "List all books",
        tags: ["Books"]
    )]
    #[OA\Response(
        response: 200,
        description: "A list of books",
        content: new OA\JsonContent(type: "array", items: new OA\Items(ref: "#/components/schemas/Book"))
    )]
    public function index(\Illuminate\Http\Request $request): AnonymousResourceCollection
    {
        $query = Book::with(['author', 'category', 'promotion', 'images'])
            ->where('stock_qty', '>', 0)
            ->withAvg('reviews', 'rating')
            ->withCount('reviews');

        if (auth('sanctum')->check()) {
            // Include exactly the authenticated user's review for this book if it exists
            $userId = auth('sanctum')->id();
            $query->with(['reviews' => function ($q) use ($userId) {
                $q->where('user_id', $userId);
            }]);
        }

        if ($request->has('condition')) {
            $query->where('condition', 'ILIKE', $request->condition);
        }

        $books = $query->get();
        return BookResource::collection($books);
    }

    #[OA\Post(
        path: "/api/books",
        summary: "Create a new book",
        tags: ["Books"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["title", "author_id", "category_id", "description", "price", "stock_qty", "condition", "status"],
            properties: [
                new OA\Property(property: "title", type: "string", example: "The Great Gatsby"),
                new OA\Property(property: "author_id", type: "integer", example: 1),
                new OA\Property(property: "category_id", type: "integer", example: 1),
                new OA\Property(property: "promotion_id", type: "integer", nullable: true),
                new OA\Property(property: "isbn", type: "string", example: "978-3-16-148410-0"),
                new OA\Property(property: "description", type: "string"),
                new OA\Property(property: "price", type: "number", format: "float", example: 19.99),
                new OA\Property(property: "stock_qty", type: "integer", example: 10),
                new OA\Property(property: "condition", type: "string", example: "new"),
                new OA\Property(property: "status", type: "string", example: "active"),
                new OA\Property(property: "video_url", type: "string", nullable: true),
                new OA\Property(
                    property: "images",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "image_url", type: "string", example: "book-images/cover.jpg"),
                            new OA\Property(property: "is_primary", type: "boolean", example: true)
                        ]
                    )
                )
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Book created successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Book")
    )]
    public function store(StoreBookRequest $request): JsonResponse
    {
        $data = $request->validated();
        $images = $data['images'] ?? [];
        unset($data['images']);

        $book = Book::create($data);

        if (!empty($images)) {
            $hasPrimary = false;
            $processedImages = [];
            
            // Reverse so we pick the LAST one marked as primary if multiple exist
            foreach (array_reverse($images) as $image) {
                $isPrimary = $image['is_primary'] && !$hasPrimary;
                if ($isPrimary) {
                    $hasPrimary = true;
                }
                
                $processedImages[] = [
                    'image_url' => $this->processImage($image['image_url']),
                    'is_primary' => $isPrimary,
                ];
            }

            $book->images()->createMany(array_reverse($processedImages));
        }

        return (new BookResource($book->load(['author', 'category', 'promotion', 'images'])))
            ->response()
            ->setStatusCode(201);
    }

    #[OA\Get(
        path: "/api/books/{id}",
        summary: "Get a specific book",
        tags: ["Books"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(
        response: 200,
        description: "Book details",
        content: new OA\JsonContent(ref: "#/components/schemas/Book")
    )]
    public function show(Book $book): BookResource
    {
        $book->load(['author', 'category', 'promotion', 'images'])
             ->loadAvg('reviews', 'rating')
             ->loadCount('reviews');
             
        if (auth('sanctum')->check()) {
             $book->load(['reviews' => function ($q) {
                 $q->where('user_id', auth('sanctum')->id());
             }]);
        }
        
        return new BookResource($book);
    }

    #[OA\Put(
        path: "/api/books/{id}",
        summary: "Update an existing book",
        tags: ["Books"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "title", type: "string"),
                new OA\Property(property: "price", type: "number", format: "float"),
                new OA\Property(property: "stock_qty", type: "integer"),
                new OA\Property(
                    property: "images",
                    type: "array",
                    items: new OA\Items(
                        properties: [
                            new OA\Property(property: "image_url", type: "string"),
                            new OA\Property(property: "is_primary", type: "boolean")
                        ]
                    )
                )
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Book updated successfully",
        content: new OA\JsonContent(ref: "#/components/schemas/Book")
    )]
    public function update(UpdateBookRequest $request, ?Book $book = null): BookResource|JsonResponse
    {
        // Fallback for when route model binding doesn't capture the book (e.g., if passed in body)
        if (!$book && $request->has('book_id')) {
            $book = Book::find($request->book_id);
        }

        if (!$book) {
            return response()->json(['message' => 'Book not found'], 404);
        }

        $data = $request->validated();
        $images = $data['images'] ?? null;
        unset($data['images']);

        $book->update($data);

        if ($request->has('images')) {
            $book->images()->delete();
            if (!empty($images)) {
                $hasPrimary = false;
                $processedImages = [];
                
                foreach (array_reverse($images) as $image) {
                    $isPrimary = $image['is_primary'] && !$hasPrimary;
                    if ($isPrimary) {
                        $hasPrimary = true;
                    }
                    
                    $processedImages[] = [
                        'image_url' => $this->processImage($image['image_url']),
                        'is_primary' => $isPrimary,
                    ];
                }

                $book->images()->createMany(array_reverse($processedImages));
            }
        }

        return new BookResource($book->load(['author', 'category', 'promotion', 'images']));
    }

    private function processImage(mixed $image): string
    {
        $directory = 'book-images';

        // 1. Handle standard file uploads (multipart)
        if ($image instanceof \Illuminate\Http\UploadedFile) {
            $fileName = Str::ulid() . '.' . $image->getClientOriginalExtension();
            return $image->storeAs($directory, $fileName, 'supabase');
        }

        if (!is_string($image)) {
            return (string) $image;
        }

        // 2. Handle base64 encoded images
        if (preg_match('/^data:image\/(\w+);base64,/', $image, $type)) {
            $data = substr($image, strpos($image, ',') + 1);
            $type = strtolower($type[1]);

            if (!in_array($type, ['jpg', 'jpeg', 'gif', 'png'])) {
                return $image;
            }
            $data = base64_decode($data);

            if ($data === false) {
                return $image;
            }

            $fileName = Str::ulid() . '.' . $type;
            $path = $directory . '/' . $fileName;

            Storage::disk('supabase')->put($path, $data);

            return $path;
        }

        // 3. Handle existing full URLs (Don't re-save, just extract the relative path)
        // If it contains 'book-images/', extract everything from there
        if (str_contains($image, 'book-images/')) {
            $parts = explode('book-images/', $image);
            return 'book-images/' . end($parts);
        }

        // 4. Handle local file paths (e.g., D://path/to/image.jpg)
        if (file_exists($image)) {
            $extension = pathinfo($image, PATHINFO_EXTENSION);
            $fileName = Str::ulid() . '.' . ($extension ?: 'jpg');
            $path = $directory . '/' . $fileName;
            
            $content = file_get_contents($image);
            Storage::disk('supabase')->put($path, $content);
            
            return $path;
        }

        return $image;
    }

    #[OA\Delete(
        path: "/api/books/{id}",
        summary: "Delete a book",
        tags: ["Books"],
        parameters: [
            new OA\Parameter(name: "id", in: "path", required: true, schema: new OA\Schema(type: "integer"))
        ]
    )]
    #[OA\Response(response: 204, description: "Book deleted successfully")]
    public function destroy(Book $book): JsonResponse
    {
        $book->delete();
        return response()->json(null, 204);
    }
}


