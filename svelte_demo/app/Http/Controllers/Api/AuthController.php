<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use OpenApi\Attributes as OA;

class AuthController extends Controller
{
    #[OA\Post(
        path: "/api/register",
        summary: "Register a new user",
        tags: ["Authentication"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["name", "email", "password", "phone"],
            properties: [
                new OA\Property(property: "name", type: "string", example: "John Doe"),
                new OA\Property(property: "email", type: "string", format: "email", example: "john@example.com"),
                new OA\Property(property: "password", type: "string", format: "password", example: "Password123!"),
                new OA\Property(property: "phone", type: "string", example: "0201234567"),
                new OA\Property(property: "role", type: "string", example: "customer"),
                new OA\Property(property: "fcm_token", type: "string", example: "fcm-token-string"),
                new OA\Property(property: "device_type", type: "string", example: "android")
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "User registered successfully",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "User registered successfully"),
                new OA\Property(property: "user", type: "object"),
                new OA\Property(property: "access_token", type: "string"),
                new OA\Property(property: "token_type", type: "string", example: "Bearer")
            ]
        )
    )]
    #[OA\Response(response: 422, description: "Validation error")]
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => $request->password,
            'phone' => $request->phone,
            'role' => $request->role ?? 'customer',
            'status' => 'active',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        if (!empty($request->fcm_token)) {
            $user->devices()->updateOrCreate(
                ['fcm_token' => $request->fcm_token],
                ['device_type' => $request->device_type]
            );
        }

        return response()->json([
            'message' => 'User registered successfully',
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'telegram_subscribe_url' => "https://t.me/hengcode_bot?start={$user->id}",
        ], 201);
    }

    #[OA\Post(
        path: "/api/login",
        summary: "Login user and create token",
        tags: ["Authentication"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["identifier", "password"],
            properties: [
                new OA\Property(property: "identifier", type: "string", example: "john@example.com", description: "Email or Phone"),
                new OA\Property(property: "password", type: "string", format: "password", example: "Password123!"),
                new OA\Property(property: "fcm_token", type: "string", example: "fcm-token-string"),
                new OA\Property(property: "device_type", type: "string", example: "android")
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Login successful",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Login successful"),
                new OA\Property(property: "user", type: "object"),
                new OA\Property(property: "access_token", type: "string"),
                new OA\Property(property: "token_type", type: "string", example: "Bearer")
            ]
        )
    )]
    #[OA\Response(response: 401, description: "Invalid login credentials")]
    public function login(LoginRequest $request): JsonResponse
    {
        $identifier = $request->identifier;
        $password = $request->password;

        // Try email first
        $user = User::where('email', $identifier)->first();
        
        // If not found by email, try phone
        if (!$user) {
            $user = User::where('phone', $identifier)->first();
        }

        if (!$user || !Hash::check($password, $user->password)) {
            return response()->json([
                'message' => 'Invalid login credentials',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        if (!empty($request->fcm_token)) {
            $user->devices()->updateOrCreate(
                ['fcm_token' => $request->fcm_token],
                ['device_type' => $request->device_type]
            );
        }

        return response()->json([
            'message' => 'Login successful',
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    #[OA\Post(
        path: "/api/logout",
        summary: "Logout user (Revoke the token)",
        tags: ["Authentication"],
        security: [["sanctum" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Logged out successfully",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Logged out successfully")
            ]
        )
    )]
    #[OA\Response(response: 401, description: "Unauthenticated")]
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }
}
