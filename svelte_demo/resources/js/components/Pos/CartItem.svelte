<script lang="ts">
    import { router } from '@inertiajs/svelte';
    
    export let item: any;
    export let id: string;

    function updateQty(newQty: number) {
        router.post(route('pos.cart.update'), { id, quantity: newQty }, { preserveScroll: true });
    }

    function remove() {
        router.delete(route('pos.cart.remove', { id }), { preserveScroll: true });
    }
</script>

<div class="flex items-center space-x-4 p-4 rounded-3xl bg-white border border-gray-50 shadow-sm hover:shadow-md transition-all duration-300">
    <div class="w-16 h-20 bg-gray-50 rounded-2xl overflow-hidden flex-shrink-0 border border-gray-100">
        {#if item.image}
            <img src={item.image} alt={item.title} class="w-full h-full object-cover" />
        {:else}
            <div class="w-full h-full flex items-center justify-center text-gray-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
            </div>
        {/if}
    </div>
    
    <div class="flex-1 min-w-0">
        <h4 class="text-sm font-black text-gray-900 truncate mb-0.5">{item.title}</h4>
        <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2">{item.author}</p>
        
        <div class="flex items-center justify-between">
            <div class="flex items-center bg-gray-50 rounded-xl p-1 border border-gray-100">
                <button on:click={() => updateQty(item.quantity - 1)} class="p-1 px-2 hover:bg-white rounded-lg transition-colors text-gray-400 hover:text-red-500">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M20 12H4" />
                    </svg>
                </button>
                <span class="text-xs font-black w-8 text-center text-gray-900">{item.quantity}</span>
                <button on:click={() => updateQty(item.quantity + 1)} class="p-1 px-2 hover:bg-white rounded-lg transition-colors text-gray-400 hover:text-blue-500">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M12 4v16m8-8H4" />
                    </svg>
                </button>
            </div>
            <div class="text-right">
                <span class="text-sm font-black text-gray-900">${(item.price * item.quantity).toFixed(2)}</span>
            </div>
        </div>
    </div>
    <button on:click={remove} class="p-2 text-gray-300 hover:text-red-500 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
    </button>
</div>
