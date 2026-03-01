<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Google_Client;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use OpenApi\Attributes as OA;

class SocialAuthController extends Controller
{
    #[OA\Post(
        path: '/api/auth/google/login',
        summary: 'Login with Google idToken',
        tags: ['Authentication']
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ['idToken'],
            properties: [
                new OA\Property(property: 'idToken', type: 'string', example: 'eyJhbGciOiJSUzI1NiIsImtp...'),
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
    #[OA\Response(response: 401, description: 'Invalid idToken')]
    public function loginWithGoogle(Request $request): JsonResponse
    {
        $request->validate([
            'idToken' => 'required|string',
        ]);

        $idToken = $request->idToken;
        $clientId = config('services.google.client_id');

        $client = app(Google_Client::class);
        $client->setClientId($clientId);

        try {
            $payload = $client->verifyIdToken($idToken);
        } catch (\Exception $e) {
            \Log::error('Google Token Verification Exception: '.$e->getMessage());

            return response()->json(['message' => 'Token verification error: '.$e->getMessage()], 401);
        }

        if (! $payload) {
            \Log::error('Google Token Verification Failed. Client ID: '.$clientId);

            return response()->json([
                'message' => 'Invalid Google idToken',
            ], 401);
        }

        $googleId = $payload['sub'];
        $email = $payload['email'];
        $name = $payload['name'] ?? 'Google User';
        $avatar = $payload['picture'] ?? null;

        // Find user by google_id or email
        $user = User::where('google_id', $googleId)->first();

        if (! $user) {
            $user = User::where('email', $email)->first();

            if ($user) {
                // Bridge existing user with google_id and sync profile data
                $user->update([
                    'google_id' => $googleId,
                    'name' => $name, // Sync name from Google
                    'avatar' => $avatar ?? $user->avatar,
                ]);
                $user->refresh();
            } else {
                // Create new user
                $user = User::create([
                    'name' => $name,
                    'email' => $email,
                    'google_id' => $googleId,
                    'avatar' => $avatar,
                    'password' => Hash::make(Str::random(24)), // Random password for security
                    'role' => 'customer',
                    'status' => 'active',
                ]);

                // Assign the Shield 'customer' role for admin panel permissions
                $user->assignRole('customer');
            }
        } else {
            // Update name and avatar if they changed or to stay in sync
            $user->update([
                'name' => $name,
                'avatar' => $avatar ?? $user->avatar,
            ]);
            $user->refresh();
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
        path: '/api/auth/facebook/login',
        summary: 'Login with Facebook accessToken',
        tags: ['Authentication']
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ['accessToken'],
            properties: [
                new OA\Property(property: 'accessToken', type: 'string', example: 'EAAG...'),
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
    #[OA\Response(response: 401, description: 'Invalid accessToken')]
    public function loginWithFacebook(Request $request): JsonResponse
    {
        $request->validate([
            'accessToken' => 'required|string',
        ]);

        $accessToken = $request->accessToken;

        try {
            // Verify Facebook Token and get user info
            $response = \Http::get('https://graph.facebook.com/me', [
                'fields' => 'id,name,email,picture.type(large)',
                'access_token' => $accessToken,
            ]);

            if ($response->failed()) {
                \Log::error('Facebook Token Verification Failed: '.$response->body());

                return response()->json(['message' => 'Invalid Facebook accessToken'], 401);
            }

            $facebookData = $response->json();
            \Log::info('Facebook Data Received:', $facebookData);

            $facebookId = $facebookData['id'];
            $email = $facebookData['email'] ?? null;
            $name = $facebookData['name'] ?? 'Facebook User';
            $avatar = $facebookData['picture']['data']['url'] ?? null;

            if (! $email && ! $facebookId) {
                return response()->json(['message' => 'Could not retrieve user info from Facebook'], 401);
            }

            // Find user by facebook_id or email
            $user = User::where('facebook_id', $facebookId)->first();

            if (! $user) {
                if ($email) {
                    $user = User::where('email', $email)->first();
                }

                if ($user) {
                    // Bridge existing user with facebook_id and sync profile data
                    $user->update([
                        'facebook_id' => $facebookId,
                        'name' => $name, // Sync name from Facebook
                        'avatar' => $avatar ?? $user->avatar, // Sync avatar from Facebook
                    ]);
                    $user->refresh();
                } else {
                    // Create new user
                    $user = User::create([
                        'name' => $name,
                        'email' => $email ?? ($facebookId.'@facebook.com'),
                        'facebook_id' => $facebookId,
                        'avatar' => $avatar,
                        'password' => Hash::make(Str::random(24)),
                        'role' => 'customer',
                        'status' => 'active',
                    ]);

                    // Assign the Shield 'customer' role for admin panel permissions
                    $user->assignRole('customer');
                }
            } else {
                // Update name and avatar if they changed or to stay in sync
                $user->update([
                    'name' => $name,
                    'avatar' => $avatar ?? $user->avatar,
                ]);
                $user->refresh();
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

        } catch (\Exception $e) {
            \Log::error('Facebook Login Exception: '.$e->getMessage());

            return response()->json(['message' => 'Server error during Facebook login'], 500);
        }
    }
}
