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
            // 1. Delete any remaining orphaned records with null ID (already done by script, but for safety)
            DB::table('books')->whereNull('id')->delete();

            // 2. Create sequence if not exists
            DB::statement('CREATE SEQUENCE IF NOT EXISTS books_id_seq');

            // 3. Set the column default to use the sequence
            DB::statement("ALTER TABLE books ALTER COLUMN id SET DEFAULT nextval('books_id_seq')");

            // 4. Set the column to NOT NULL (if it isn't already)
            DB::statement('ALTER TABLE books ALTER COLUMN id SET NOT NULL');

            // 5. Add Primary Key constraint if not exists
            // We check for existing PK first to avoid errors
            $hasPk = DB::selectOne("
                SELECT count(*) FROM information_schema.table_constraints 
                WHERE table_name = 'books' AND constraint_type = 'PRIMARY KEY'
            ")->count > 0;

            if (! $hasPk) {
                DB::statement('ALTER TABLE books ADD PRIMARY KEY (id)');
            }

            // 6. Sync the sequence with the current max ID
            DB::statement("SELECT setval('books_id_seq', COALESCE((SELECT MAX(id) FROM books), 0) + 1, false)");
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
        // Keep it simple
    }
};
