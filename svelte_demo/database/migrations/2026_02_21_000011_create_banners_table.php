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
        Schema::create('banners', function (Blueprint $table) {
            $table->id();
            $table->string('title', 255)->nullable();
            $table->string('image_url', 255);
            $table->string('action_type', 50)->default('none'); // promotion, book, category, url, none
            $table->integer('action_id')->nullable();
            $table->string('action_url', 255)->nullable();
            $table->integer('display_order')->default(0);
            $table->string('status', 20)->default('active'); // active, inactive
            $table->timestamp('start_date')->nullable();
            $table->timestamp('end_date')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('banners');
    }
};
