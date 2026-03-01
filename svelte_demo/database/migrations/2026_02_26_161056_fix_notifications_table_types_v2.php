<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            // Ensure we are on PostgreSQL before running these raw statements
            if (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE notifications ALTER COLUMN id TYPE uuid USING id::uuid');
                DB::statement('ALTER TABLE notifications ALTER COLUMN data TYPE jsonb USING data::jsonb');
                DB::statement('ALTER TABLE notifications ALTER COLUMN read_at TYPE timestamp USING read_at::timestamp');
                DB::statement('ALTER TABLE notifications ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
                DB::statement('ALTER TABLE notifications ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
                DB::statement('ALTER TABLE notifications ALTER COLUMN notifiable_id TYPE bigint USING notifiable_id::bigint');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            if (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE notifications ALTER COLUMN id TYPE varchar(255)');
                DB::statement('ALTER TABLE notifications ALTER COLUMN data TYPE varchar(255)');
                DB::statement('ALTER TABLE notifications ALTER COLUMN read_at TYPE varchar(255)');
                DB::statement('ALTER TABLE notifications ALTER COLUMN created_at TYPE varchar(255)');
                DB::statement('ALTER TABLE notifications ALTER COLUMN updated_at TYPE varchar(255)');
                DB::statement('ALTER TABLE notifications ALTER COLUMN notifiable_id TYPE varchar(255)');
            }
        });
    }
};
