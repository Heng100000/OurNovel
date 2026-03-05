<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->string('subtitle', 255)->nullable()->after('title');
            $table->text('description')->nullable()->after('subtitle');
            $table->integer('discount_percentage')->nullable()->after('image_url');
            $table->string('button_text', 50)->nullable()->after('discount_percentage');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->dropColumn(['subtitle', 'description', 'discount_percentage', 'button_text']);
        });
    }
};
