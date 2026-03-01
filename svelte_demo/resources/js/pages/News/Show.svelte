<script lang="ts">

    export let news: {
        title: string;
        description: string;
        image_url: string | null;
        category: string;
        created_at: string;
    };
    export let meta: {
        title: string;
        description: string;
        image: string | null;
        url: string;
    };
</script>

<svelte:head>
    <title>{meta.title}</title>
    <meta name="description" content={meta.description} />
    
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="article" />
    <meta property="og:url" content={meta.url} />
    <meta property="og:title" content={meta.title} />
    <meta property="og:description" content={meta.description} />
    {#if meta.image}
        <meta property="og:image" content={meta.image} />
    {/if}

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content={meta.url} />
    <meta property="twitter:title" content={meta.title} />
    <meta property="twitter:description" content={meta.description} />
    {#if meta.image}
        <meta property="twitter:image" content={meta.image} />
    {/if}
</svelte:head>

<div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8 dark:bg-zinc-900">
    <div class="max-w-3xl mx-auto bg-white rounded-2xl shadow-xl overflow-hidden dark:bg-zinc-800">
        {#if news.image_url}
            <div class="h-64 sm:h-96 w-full relative">
                <img 
                    src={news.image_url} 
                    alt={news.title}
                    class="w-full h-full object-cover"
                />
                <div class="absolute top-4 left-4">
                    <span class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-indigo-600 text-white shadow-lg">
                        {news.category}
                    </span>
                </div>
            </div>
        {/if}

        <div class="p-8 sm:p-12">
            <div class="flex items-center text-sm text-gray-500 mb-4 dark:text-zinc-400">
                <time datetime={news.created_at}>{news.created_at}</time>
            </div>

            <h1 class="text-3xl sm:text-4xl font-extrabold text-zinc-900 mb-6 dark:text-white leading-tight">
                {news.title}
            </h1>

            <div class="prose prose-lg max-w-none text-zinc-600 dark:text-zinc-300 dark:prose-invert">
                {@html news.description}
            </div>

            <div class="mt-12 pt-8 border-t border-gray-100 dark:border-zinc-700">
                <a 
                    href="/" 
                    class="inline-flex items-center text-indigo-600 font-semibold hover:text-indigo-500 transition-colors"
                >
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
                    </svg>
                    Back to Website
                </a>
            </div>
        </div>
    </div>
</div>

<style>
    /* Add any custom styles here */
</style>
