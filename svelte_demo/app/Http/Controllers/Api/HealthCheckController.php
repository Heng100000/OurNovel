<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

#[OA\Info(
    title: "Laravel Svelte Starter API",
    version: "1.0.0",
    description: "API documentation for the Laravel Svelte Starter Kit"
)]
#[OA\Server(
    url: L5_SWAGGER_CONST_HOST,
    description: "Primary API Server"
)]
#[OA\SecurityScheme(
    securityScheme: "sanctum",
    type: "apiKey",
    name: "Authorization",
    in: "header",
    description: "Enter token in format (Bearer <token>)"
)]
class HealthCheckController extends Controller
{
    #[OA\Get(
        path: "/api/health",
        summary: "Check API Health",
        description: "Returns the status of the API",
        tags: ["System"]
    )]
    #[OA\Response(
        response: 200,
        description: "Successful operation",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "status", type: "string", example: "up"),
                new OA\Property(property: "timestamp", type: "string", example: "2024-02-21T10:00:00Z")
            ]
        )
    )]
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'status' => 'up',
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
