<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

test('user can register with default customer role', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'Linh Sokheng',
        'email' => 'heng1900@gmail.com',
        'password' => 'heng12345',
        'phone' => '011414213',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email', 'phone', 'role', 'status'],
            'access_token',
            'token_type',
        ])
        ->assertJsonPath('user.role', 'customer');

    $this->assertDatabaseHas('users', [
        'email' => 'heng1900@gmail.com',
        'role' => 'customer',
    ]);

    $user = User::where('email', 'heng1900@gmail.com')->first();
    expect(Hash::check('heng12345', $user->password))->toBeTrue();
});

test('user can register with specific role', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'Admin User',
        'email' => 'admin@example.com',
        'password' => 'password123',
        'phone' => '011223344',
        'role' => 'admin',
    ]);

    $response->assertStatus(201)
        ->assertJsonPath('user.role', 'admin');
});

test('user can login', function () {
    $user = User::factory()->create([
        'email' => 'login@example.com',
        'password' => 'password',
    ]);

    $response = $this->postJson('/api/login', [
        'identifier' => 'login@example.com',
        'password' => 'password',
    ]);

    $response->assertStatus(200)
        ->assertJsonStructure([
            'message',
            'user',
            'access_token',
            'token_type',
        ]);
});

test('authenticated user can logout', function () {
    $user = User::factory()->create();
    $token = $user->createToken('auth_token')->plainTextToken;

    $response = $this->withHeader('Authorization', 'Bearer '.$token)
        ->postJson('/api/logout');

    $response->assertStatus(200)
        ->assertJson([
            'message' => 'Logged out successfully',
        ]);

    $this->assertCount(0, $user->tokens);
});
