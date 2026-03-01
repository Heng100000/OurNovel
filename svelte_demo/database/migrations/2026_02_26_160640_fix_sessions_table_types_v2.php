<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('ALTER TABLE sessions ALTER COLUMN payload TYPE text');
        DB::statement('ALTER TABLE sessions ALTER COLUMN user_agent TYPE text');
        DB::statement('ALTER TABLE sessions ALTER COLUMN ip_address TYPE varchar(45)');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('ALTER TABLE sessions ALTER COLUMN payload TYPE varchar(255)');
        DB::statement('ALTER TABLE sessions ALTER COLUMN user_agent TYPE varchar(255)');
        DB::statement('ALTER TABLE sessions ALTER COLUMN ip_address TYPE varchar(255)');
    }
};
