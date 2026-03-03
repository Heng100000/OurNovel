<script lang="ts">
    import { router, page } from '@inertiajs/svelte';
    
    let { book }: { book: any } = $props();
    
    let isAdding = $state(false);

    // Dynamic storage configuration from Inertia shared data
    const supabaseUrl = $page.props.storage?.supabase_url;
    const supabaseBucket = $page.props.storage?.supabase_bucket;
    const baseUrl = (supabaseUrl as string)?.split('/storage/v1/')[0];

    function addToCart() {
        isAdding = true;
        router.post(route('pos.cart.add'), { book_id: book.id }, {
            preserveScroll: true,
            onFinish: () => isAdding = false
        });
    }

    // Image URL logic
    const primaryImage = book.primary_image;
    
    // Construct URLs dynamically
    const optimizedUrl = primaryImage && baseUrl 
        ? `${baseUrl}/storage/v1/render/image/public/${supabaseBucket}/${primaryImage.image_url.replace(/^\//, '')}?width=400&height=533&quality=70` 
        : null;

    const directUrl = primaryImage && baseUrl 
        ? `${baseUrl}/storage/v1/object/public/${supabaseBucket}/${primaryImage.image_url.replace(/^\//, '')}` 
        : null;

    function handleImageError(e: Event) {
        const img = e.target as HTMLImageElement;
        if (img.src !== directUrl && directUrl) {
            img.src = directUrl;
        } else {
            img.onerror = null;
        }
    }
</script>

<div class="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-2xl transition-all duration-500 group flex flex-col h-full transform hover:-translate-y-2">
    <div class="relative aspect-[3/4] bg-gray-50 overflow-hidden">
        {#if primaryImage}
            <img 
                src={optimizedUrl} 
                onerror={handleImageError}
                alt={book.title} 
                class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" 
            />
        {:else}
            <div class="w-full h-full flex flex-col items-center justify-center text-gray-300 bg-gray-50">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mb-2 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
                <span class="text-xs font-bold uppercase tracking-widest text-gray-400">No Cover</span>
            </div>
        {/if}

        {#if book.discounted_price}
            <div class="absolute top-4 right-4 bg-red-500 text-white text-[10px] font-black px-3 py-1.5 rounded-full shadow-lg z-10 animate-pulse uppercase tracking-tighter">
                Save {Math.round((1 - book.discounted_price / book.price) * 100)}%
            </div>
        {/if}
    </div>

    <div class="p-5 flex flex-col flex-1">
        <h3 class="font-black text-gray-900 line-clamp-2 min-h-[3rem] text-sm sm:text-base mb-1 group-hover:text-[#0d6a3d] transition-colors">
            {book.title}
        </h3>
        <p class="text-xs font-bold text-[#0d6a3d] mb-4 uppercase tracking-widest">
            {book.author?.name || 'Unknown Author'}
        </p>
        
        <div class="mt-auto">
            <div class="flex items-baseline space-x-2 mb-4">
                {#if book.discounted_price}
                    <span class="text-xl font-black text-gray-900">${book.discounted_price}</span>
                    <span class="text-xs font-bold text-gray-400 line-through decoration-red-400">${book.price}</span>
                {:else}
                    <span class="text-xl font-black text-gray-900">${book.price}</span>
                {/if}
            </div>

            <button 
                onclick={addToCart} 
                disabled={isAdding} 
                class="w-full bg-gray-900 hover:bg-[#0d6a3d] disabled:bg-gray-400 text-white font-black py-3.5 rounded-2xl transition-all duration-300 shadow-md hover:shadow-[#0d6a3d]/10 active:scale-95 flex items-center justify-center space-x-2 group-btn"
            >
                {#if isAdding}
                    <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                {:else}
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 transition-transform group-btn-hover:scale-125" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                {/if}
                <span class="uppercase text-xs tracking-widest font-black">Add to Cart</span>
            </button>
        </div>
    </div>
</div>

<style>
    .group-btn:hover :global(svg) {
        transform: scale(1.25);
    }
</style>
