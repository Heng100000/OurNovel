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
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        DB::transaction(function () {
            // Standardize format before altering (already done by script, but for safety)
            // We use raw SQL to handle potential conversion issues during the transaction

            DB::statement('ALTER TABLE users ALTER COLUMN email_verified_at TYPE timestamp WITHOUT TIME ZONE USING email_verified_at::timestamp WITHOUT TIME ZONE');
            DB::statement('ALTER TABLE users ALTER COLUMN two_factor_confirmed_at TYPE timestamp WITHOUT TIME ZONE USING two_factor_confirmed_at::timestamp WITHOUT TIME ZONE');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->string('email_verified_at')->change();
            $table->string('two_factor_confirmed_at')->change();
        });
    }
};
