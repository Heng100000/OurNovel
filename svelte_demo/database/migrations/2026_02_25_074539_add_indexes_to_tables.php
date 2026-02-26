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
        Schema::table('books', function (Blueprint $table) {
            $table->index('title');
            $table->index('isbn');
            $table->index('status');
            $table->index('price');
            $table->index('stock_qty');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->index('name');
            $table->index('role');
            $table->index('status');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->index('status');
            $table->index('total_price');
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->index('invoice_no');
            $table->index('grand_total');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('books', function (Blueprint $table) {
            $table->dropIndex(['title']);
            $table->dropIndex(['isbn']);
            $table->dropIndex(['status']);
            $table->dropIndex(['price']);
            $table->dropIndex(['stock_qty']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['name']);
            $table->dropIndex(['role']);
            $table->dropIndex(['status']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropIndex(['total_price']);
        });

        Schema::table('invoices', function (Blueprint $table) {
            $table->dropIndex(['invoice_no']);
            $table->dropIndex(['grand_total']);
        });
    }
};
