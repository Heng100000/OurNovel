<?php

use Illuminate\Database\Migrations\Migration;

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
            // --- Books ---
            DB::statement('ALTER TABLE books ALTER COLUMN price TYPE numeric(12,2) USING price::numeric(12,2)');
            DB::statement('ALTER TABLE books ALTER COLUMN promotion_id TYPE bigint USING promotion_id::bigint');

            // --- Categories ---
            DB::statement('ALTER TABLE categories ALTER COLUMN parent_id TYPE bigint USING parent_id::bigint');

            // --- Banners ---
            DB::statement('TRUNCATE TABLE banners RESTART IDENTITY CASCADE'); // Safety since it matches current state (empty)
            DB::statement('ALTER TABLE banners ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE banners ALTER COLUMN id SET NOT NULL');
            DB::statement('ALTER TABLE banners ALTER COLUMN display_order TYPE integer USING display_order::integer');
            DB::statement('ALTER TABLE banners ALTER COLUMN start_date TYPE timestamp USING start_date::timestamp');
            DB::statement('ALTER TABLE banners ALTER COLUMN end_date TYPE timestamp USING end_date::timestamp');
            DB::statement('ALTER TABLE banners ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE banners ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            // Ensure PK exists
            DB::statement('DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = \'banners_pkey\') THEN ALTER TABLE banners ADD PRIMARY KEY (id); END IF; END $$');
            // Ensure sequence exists if not already autoincrement
            DB::statement('CREATE SEQUENCE IF NOT EXISTS banners_id_seq');
            DB::statement('ALTER TABLE banners ALTER COLUMN id SET DEFAULT nextval(\'banners_id_seq\')');

            // --- News Announcements ---
            DB::statement('TRUNCATE TABLE news_announcements RESTART IDENTITY CASCADE');
            DB::statement('ALTER TABLE news_announcements ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE news_announcements ALTER COLUMN id SET NOT NULL');
            DB::statement('ALTER TABLE news_announcements ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE news_announcements ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = \'news_announcements_pkey\') THEN ALTER TABLE news_announcements ADD PRIMARY KEY (id); END IF; END $$');
            DB::statement('CREATE SEQUENCE IF NOT EXISTS news_announcements_id_seq');
            DB::statement('ALTER TABLE news_announcements ALTER COLUMN id SET DEFAULT nextval(\'news_announcements_id_seq\')');

            // --- Book Images ---
            DB::statement('ALTER TABLE book_images ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE book_images ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');

            // --- Promotions ---
            DB::statement('TRUNCATE TABLE promotions RESTART IDENTITY CASCADE');
            DB::statement('ALTER TABLE promotions ALTER COLUMN id TYPE bigint USING id::bigint');
            DB::statement('ALTER TABLE promotions ALTER COLUMN id SET NOT NULL');
            DB::statement('ALTER TABLE promotions ALTER COLUMN discount_value TYPE numeric(10,2) USING discount_value::numeric(10,2)');
            DB::statement('ALTER TABLE promotions ALTER COLUMN start_date TYPE timestamp USING start_date::timestamp');
            DB::statement('ALTER TABLE promotions ALTER COLUMN end_date TYPE timestamp USING end_date::timestamp');
            DB::statement('ALTER TABLE promotions ALTER COLUMN created_at TYPE timestamp USING created_at::timestamp');
            DB::statement('ALTER TABLE promotions ALTER COLUMN updated_at TYPE timestamp USING updated_at::timestamp');
            DB::statement('ALTER TABLE promotions ALTER COLUMN event_id TYPE bigint USING event_id::bigint');
            DB::statement('DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = \'promotions_pkey\') THEN ALTER TABLE promotions ADD PRIMARY KEY (id); END IF; END $$');
            DB::statement('CREATE SEQUENCE IF NOT EXISTS promotions_id_seq');
            DB::statement('ALTER TABLE promotions ALTER COLUMN id SET DEFAULT nextval(\'promotions_id_seq\')');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
