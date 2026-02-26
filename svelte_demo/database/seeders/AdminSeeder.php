<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@bookstore.com'],
            [
                'name' => 'System administrator',
                'password' => Hash::make('password'),
                'phone' => '0999999999',
                'role' => 'admin',
                'status' => 'active',
            ]
        );
    }
}
