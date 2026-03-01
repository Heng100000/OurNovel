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

        DB::transaction(function () {
            // --- Payments ---
            DB::statement('ALTER TABLE payments ALTER COLUMN amount TYPE numeric(12,2) USING amount::numeric(12,2)');
            DB::statement('ALTER TABLE payments ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE payments ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE payments ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE payments ALTER COLUMN order_id TYPE bigint USING order_id::bigint');

            // --- Orders ---
            DB::statement('ALTER TABLE orders ALTER COLUMN subtotal TYPE numeric(12,2) USING subtotal::numeric(12,2)');
            DB::statement('ALTER TABLE orders ALTER COLUMN total_price TYPE numeric(12,2) USING total_price::numeric(12,2)');
            DB::statement('ALTER TABLE orders ALTER COLUMN shipping_fee TYPE numeric(12,2) USING shipping_fee::numeric(12,2)');
            DB::statement('ALTER TABLE orders ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE orders ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE orders ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE orders ALTER COLUMN user_id TYPE bigint USING user_id::bigint');
            DB::statement('ALTER TABLE orders ALTER COLUMN address_id TYPE bigint USING address_id::bigint');
            DB::statement('ALTER TABLE orders ALTER COLUMN delivery_company_id TYPE bigint USING delivery_company_id::bigint');

            // --- Order Items ---
            DB::statement('ALTER TABLE order_items ALTER COLUMN unit_price TYPE numeric(12,2) USING unit_price::numeric(12,2)');
            DB::statement('ALTER TABLE order_items ALTER COLUMN quantity TYPE integer USING quantity::integer');
            DB::statement('ALTER TABLE order_items ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE order_items ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE order_items ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE order_items ALTER COLUMN order_id TYPE bigint USING order_id::bigint');
            DB::statement('ALTER TABLE order_items ALTER COLUMN book_id TYPE bigint USING book_id::bigint');

            // --- Invoices ---
            DB::statement('ALTER TABLE invoices ALTER COLUMN sub_total TYPE numeric(12,2) USING sub_total::numeric(12,2)');
            DB::statement('ALTER TABLE invoices ALTER COLUMN tax_amount TYPE numeric(12,2) USING tax_amount::numeric(12,2)');
            DB::statement('ALTER TABLE invoices ALTER COLUMN shipping_fee TYPE numeric(12,2) USING shipping_fee::numeric(12,2)');
            DB::statement('ALTER TABLE invoices ALTER COLUMN grand_total TYPE numeric(12,2) USING grand_total::numeric(12,2)');
            DB::statement('ALTER TABLE invoices ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE invoices ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE invoices ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE invoices ALTER COLUMN order_id TYPE bigint USING order_id::bigint');

            // --- Shippings ---
            DB::statement('ALTER TABLE shippings ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE shippings ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE shippings ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE shippings ALTER COLUMN order_id TYPE bigint USING order_id::bigint');
            DB::statement('ALTER TABLE shippings ALTER COLUMN delivery_company_id TYPE bigint USING delivery_company_id::bigint');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void {}
};
