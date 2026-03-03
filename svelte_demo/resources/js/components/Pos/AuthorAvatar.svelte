<script lang="ts">
    import { page } from '@inertiajs/svelte';
    
    let { 
        author, 
        selected = false,
        onclick
    }: {
        author: any;
        selected?: boolean;
        onclick: () => void;
    } = $props();
    
    // Dynamic storage configuration from Inertia shared data
    const supabaseUrl = $page.props.storage?.supabase_url;
    const supabaseBucket = $page.props.storage?.supabase_bucket;

    function handleImageError(e: Event) {
        const img = e.target as HTMLImageElement;
        img.onerror = null;
        if (supabaseUrl && author.profile_image) {
            // Use the base URL from config instead of hardcoded one
            const baseUrl = (supabaseUrl as string).split('/storage/v1/')[0];
            img.src = `${baseUrl}/storage/v1/object/public/${supabaseBucket}/${author.profile_image.replace(/^\//, '')}`;
        }
    }
</script>

<button {onclick} 
    class="flex flex-col items-center group transition-all duration-300"
    title={author.name}
>
    <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-full overflow-hidden mb-2 border-2 transition-all duration-300
        {selected ? 'border-[#0d6a3d] ring-4 ring-[#0d6a3d]/10 shadow-lg scale-105' : 'border-white group-hover:border-gray-200 shadow-sm'}">
        {#if author.profile_image}
            <img 
                src={author.profile_image} 
                alt={author.name}
                onerror={handleImageError}
                class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
            />
        {:else}
            <div class="w-full h-full bg-[#0d6a3d]/5 flex items-center justify-center text-[#0d6a3d]">
                <span class="text-2xl font-bold uppercase">{author.name.charAt(0)}</span>
            </div>
        {/if}
    </div>
    <span class="text-xs font-bold text-center leading-tight truncate w-full transition-colors
        {selected ? 'text-[#0d6a3d]' : 'text-gray-500 group-hover:text-gray-800'}">
        {author.name}
    </span>
</button>
