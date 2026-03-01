<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Mockery\MockInterface;

uses(RefreshDatabase::class);

test('user can login or register with google idToken', function () {
    // Mock Google_Client
    $mockPayload = [
        'sub' => '123456789',
        'email' => 'google-user@example.com',
        'name' => 'Google User',
        'picture' => 'https://example.com/avatar.jpg',
    ];

    $this->mock(Google_Client::class, function (MockInterface $mock) use ($mockPayload) {
        $mock->shouldReceive('setClientId')->once();
        $mock->shouldReceive('verifyIdToken')->once()->andReturn($mockPayload);
    });

    Config::set('services.google.client_id', 'fake-client-id');

    $response = $this->postJson('/api/auth/google/login', [
        'idToken' => 'fake-token',
    ]);

    $response->assertStatus(200)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email', 'google_id', 'avatar'],
            'access_token',
        ])
        ->assertJsonPath('user.email', 'google-user@example.com')
        ->assertJsonPath('user.google_id', '123456789');

    $this->assertDatabaseHas('users', [
        'email' => 'google-user@example.com',
        'google_id' => '123456789',
    ]);
});

test('invalid google idToken returns 401', function () {
    $this->mock(Google_Client::class, function (MockInterface $mock) {
        $mock->shouldReceive('setClientId')->once();
        $mock->shouldReceive('verifyIdToken')->once()->andReturn(false);
    });

    $response = $this->postJson('/api/auth/google/login', [
        'idToken' => 'invalid-token',
    ]);

    $response->assertStatus(401)
        ->assertJson(['message' => 'Invalid Google idToken']);
});
