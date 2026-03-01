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
        Schema::table('news_announcements', function (Blueprint $table) {
            $table->foreignId('news_type_id')->nullable()->after('id')->constrained('news_types')->onDelete('cascade');
        });

        // Migrate data
        $newsTypes = DB::table('news_types')->pluck('id', 'name');
        
        DB::table('news_announcements')->get()->each(function ($news) use ($newsTypes) {
            $typeName = $news->newstype ?? $news->type_news ?? 'General';
            $typeId = $newsTypes[$typeName] ?? $newsTypes['General'] ?? null;
            
            if ($typeId) {
                DB::table('news_announcements')->where('id', $news->id)->update(['news_type_id' => $typeId]);
            }
        });

        Schema::table('news_announcements', function (Blueprint $table) {
            $table->dropColumn(['type_news', 'newstype']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('news_announcements', function (Blueprint $table) {
            $table->string('type_news')->default('General')->after('title');
            $table->string('newstype')->default('General')->after('type_news');
        });

        // Reverse data migration
        DB::table('news_announcements')->with('news_type_id')->get()->each(function ($news) {
            $typeName = DB::table('news_types')->where('id', $news->news_type_id)->value('name');
            DB::table('news_announcements')->where('id', $news->id)->update([
                'type_news' => $typeName,
                'newstype' => $typeName
            ]);
        });

        Schema::table('news_announcements', function (Blueprint $table) {
            $table->dropForeign(['news_type_id']);
            $table->dropColumn('news_type_id');
        });
    }
};
