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
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['address_id']);
            $table->unsignedBigInteger('address_id')->nullable()->change();
            $table->foreign('address_id')->references('id')->on('user_addresses')->onDelete('set null');

            $table->string('delivery_method')->default('delivery')->after('id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('delivery_method');

            $table->dropForeign(['address_id']);
            $table->unsignedBigInteger('address_id')->nullable(false)->change();
            $table->foreign('address_id')->references('id')->on('user_addresses')->onDelete('restrict');
        });
    }
};
