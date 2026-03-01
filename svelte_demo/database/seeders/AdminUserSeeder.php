<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create the 'admin' role
        $adminRole = Role::firstOrCreate([
            'name' => 'admin',
            'guard_name' => 'web',
        ]);

        // 2. Give the admin role all permissions EXCEPT role/permission management
        //    Those are reserved for super_admin only.
        $permissions = Permission::whereNotIn('name', [
            'view_role',
            'view_any_role',
            'create_role',
            'update_role',
            'delete_role',
            'delete_any_role',
        ])->get();

        $adminRole->syncPermissions($permissions);

        $this->command->info("Admin role created with {$permissions->count()} permissions.");

        // 3. Create (or find) the admin user account
        $user = User::firstOrCreate(
            ['email' => 'admin@ourmovie.com'],
            [
                'name' => 'Admin',
                'email' => 'admin@ourmovie.com',
                'password' => Hash::make('Admin@12345'),
                'role' => 'admin',
                'status' => 'active',
            ]
        );

        // 4. Assign the admin role
        if (! $user->hasRole('admin')) {
            $user->assignRole($adminRole);
        }

        $this->command->info('Admin user ready: email=admin@ourmovie.com | password=Admin@12345');
    }
}
