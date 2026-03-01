<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use OpenApi\Attributes as OA;

class AuthController extends Controller
{
    #[OA\Post(
        path: '/api/register',
        summary: 'Register a new user',
        tags: ['Authentication']
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ['name', 'email', 'password', 'phone'],
            properties: [
                new OA\Property(property: 'name', type: 'string', example: 'John Doe'),
                new OA\Property(property: 'email', type: 'string', format: 'email', example: 'john@example.com'),
                new OA\Property(property: 'password', type: 'string', format: 'password', example: 'Password123!'),
                new OA\Property(property: 'phone', type: 'string', example: '0201234567'),
                new OA\Property(property: 'role', type: 'string', example: 'customer'),
                new OA\Property(property: 'fcm_token', type: 'string', example: 'fcm-token-string'),
                new OA\Property(property: 'device_type', type: 'string', example: 'android'),
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: 'User registered successfully',
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'message', type: 'string', example: 'User registered successfully'),
                new OA\Property(property: 'user', type: 'object'),
                new OA\Property(property: 'access_token', type: 'string'),
                new OA\Property(property: 'token_type', type: 'string', example: 'Bearer'),
            ]
        )
    )]
    #[OA\Response(response: 422, description: 'Validation error')]
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

        // Assign the Shield 'customer' role for admin panel permissions
        $user->assignRole('customer');

        $token = $user->createToken('auth_token')->plainTextToken;

        if (! empty($request->fcm_token)) {
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
        path: '/api/login',
        summary: 'Login user and create token',
        tags: ['Authentication']
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ['identifier', 'password'],
            properties: [
                new OA\Property(property: 'identifier', type: 'string', example: 'john@example.com', description: 'Email or Phone'),
                new OA\Property(property: 'password', type: 'string', format: 'password', example: 'Password123!'),
                new OA\Property(property: 'fcm_token', type: 'string', example: 'fcm-token-string'),
                new OA\Property(property: 'device_type', type: 'string', example: 'android'),
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: 'Login successful',
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'message', type: 'string', example: 'Login successful'),
                new OA\Property(property: 'user', type: 'object'),
                new OA\Property(property: 'access_token', type: 'string'),
                new OA\Property(property: 'token_type', type: 'string', example: 'Bearer'),
            ]
        )
    )]
    #[OA\Response(response: 401, description: 'Invalid login credentials')]
    public function login(LoginRequest $request): JsonResponse
    {
        $identifier = $request->identifier;
        $password = $request->password;

        // Try email first
        $user = User::where('email', $identifier)->first();

        // If not found by email, try phone
        if (! $user) {
            $user = User::where('phone', $identifier)->first();
        }

        if (! $user || ! Hash::check($password, $user->password)) {
            return response()->json([
                'message' => 'Invalid login credentials',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        if (! empty($request->fcm_token)) {
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
        path: '/api/logout',
        summary: 'Logout user (Revoke the token)',
        tags: ['Authentication'],
        security: [['sanctum' => []]]
    )]
    #[OA\Response(
        response: 200,
        description: 'Logged out successfully',
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'message', type: 'string', example: 'Logged out successfully'),
            ]
        )
    )]
    #[OA\Response(response: 401, description: 'Unauthenticated')]
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }

    #[OA\Post(
        path: '/api/user/profile',
        summary: 'Update user profile (name, email, avatar)',
        tags: ['Authentication'],
        security: [['sanctum' => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\MediaType(
            mediaType: 'multipart/form-data',
            schema: new OA\Schema(
                required: ['name', 'email'],
                properties: [
                    new OA\Property(property: 'name', type: 'string', example: 'John Doe'),
                    new OA\Property(property: 'email', type: 'string', format: 'email', example: 'john@example.com'),
                    new OA\Property(property: 'avatar', type: 'string', format: 'binary', description: 'Avatar image file'),
                ]
            )
        )
    )]
    #[OA\Response(
        response: 200,
        description: 'Profile updated successfully',
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'message', type: 'string', example: 'Profile updated successfully'),
                new OA\Property(property: 'user', type: 'object'),
            ]
        )
    )]
    #[OA\Response(response: 422, description: 'Validation error')]
    public function updateProfile(Request $request): JsonResponse
    {
        \Illuminate\Support\Facades\Log::info('Update Profile Full Request', [
            'all' => $request->all(),
            'files' => $request->allFiles(),
            'content_type' => $request->header('Content-Type'),
            'user_id' => $request->user()?->id,
        ]);
        
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json(['message' => 'User not found or not authenticated'], 401);
            }

            $rules = [
                'name' => 'required|string|max:150',
                'email' => 'required|string|email|max:150|unique:users,email,' . $user->id,
                'bio' => 'nullable|string|max:1000',
            ];

            if ($request->hasFile('avatar')) {
                $rules['avatar'] = 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120';
            }

            $request->validate($rules);

            $user->name = $request->name;
            $user->email = $request->email;
            $user->bio = $request->bio;

            if ($request->hasFile('avatar')) {
                \Illuminate\Support\Facades\Log::info('Supabase Avatar upload detected for user: ' . $user->id);
                // Delete old avatar if it exists
                if ($user->avatar && \Illuminate\Support\Facades\Storage::disk('supabase')->exists($user->avatar)) {
                    \Illuminate\Support\Facades\Storage::disk('supabase')->delete($user->avatar);
                }
                // Delete old profile_photo if it exists and is different
                if ($user->profile_photo && $user->profile_photo !== $user->avatar && \Illuminate\Support\Facades\Storage::disk('supabase')->exists($user->profile_photo)) {
                    \Illuminate\Support\Facades\Storage::disk('supabase')->delete($user->profile_photo);
                }

                $file = $request->file('avatar');
                // Store on supabase disk
                $path = $file->store('avatars', 'supabase');
                
                if (!$path) {
                    \Illuminate\Support\Facades\Log::error('Failed to store avatar on Supabase for user: ' . $user->id);
                    return response()->json(['message' => 'The avatar failed to upload to Supabase.'], 500);
                }
                
                $user->avatar = $path;
                \Illuminate\Support\Facades\Log::info('Avatar stored on Supabase at: ' . $path);
            }

            $user->save();

            return response()->json([
                'message' => 'Profile updated successfully',
                'user' => $user->fresh(),
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            \Illuminate\Support\Facades\Log::warning('Profile validation failed: ' . json_encode($e->errors()));
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Profile update error: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred during profile update',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
