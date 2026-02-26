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
        Schema::create('books', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->onDelete('restrict');
            $table->foreignId('author_id')->constrained()->onDelete('restrict');
            $table->foreignId('promotion_id')->nullable()->constrained('promotions')->onDelete('set null');
            $table->string('title', 255);
            $table->string('isbn', 50)->nullable();
            $table->text('description');
            $table->decimal('price', 10, 2);
            $table->string('condition', 20); // Brand New, Like New, Old
            $table->integer('stock_qty')->default(1);
            $table->string('status', 20)->default('active'); // active, out_of_stock, hidden
            $table->string('video_url', 255)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('books');
    }
};
