<script lang="ts">
    import { router, page } from '@inertiajs/svelte';
    import AuthorAvatar from '@/components/Pos/AuthorAvatar.svelte';
    import BookCard from '@/components/Pos/BookCard.svelte';
    import CartItem from '@/components/Pos/CartItem.svelte';
    import { onMount, onDestroy } from 'svelte';
    import axios from 'axios';

    let { 
        books, 
        authors, 
        categories, 
        cart, 
        filters 
    }: {
        books: any;
        authors: any;
        categories: any;
        cart: any;
        filters: any;
    } = $props();

    // UI States
    let showCart = $state(false);

    // Reactive states for filters
    let search = $state(filters.search || '');
    let selectedAuthorId = $state(filters.author_id || null);
    let selectedCategoryId = $state(filters.category_id || null);

    // Sync local state when props change
    $effect(() => {
        search = filters.search || '';
        selectedAuthorId = filters.author_id || null;
        selectedCategoryId = filters.category_id || null;
    });

    let searchTimeout: any;

    function handleSearch() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            updateFilters();
        }, 500);
    }

    function selectAuthor(id: number | null) {
        selectedAuthorId = id;
        updateFilters();
    }

    function updateFilters() {
        router.get(route('pos'), {
            search: search || undefined,
            author_id: selectedAuthorId || undefined,
            category_id: selectedCategoryId || undefined
        }, {
            preserveState: true,
            preserveScroll: true,
            replace: true
        });
    }

    // Cart Logic
    const cartItems = $derived(Object.entries(cart).map(([id, details]: [string, any]) => ({ id, ...details })));
    const subtotal = $derived(cartItems.reduce((acc: number, item: any) => acc + (item.price * item.quantity), 0));

    // Checkout Logic
    let showPaymentModal = $state(false);
    let qrCodeUrl = $state('');
    let currentOrder: any = $state(null);
    let paymentStatus = $state('pending');
    let pollInterval: any;

    async function checkout() {
        try {
            const response = await axios.post(route('pos.checkout'));
            const data = response.data;
            qrCodeUrl = data.qrCodeUrl;
            currentOrder = data.order;
            paymentStatus = 'pending';
            showPaymentModal = true;
        } catch (error: any) {
            alert(error.response?.data?.error || 'Checkout failed');
        }
    }

    function closePaymentModal() {
        showPaymentModal = false;
        clearInterval(pollInterval);
        if (paymentStatus === 'paid') {
            router.reload();
        }
    }

    onDestroy(() => {
        clearInterval(pollInterval);
    });
</script>

<div class="min-h-screen bg-[#FDFDFF] font-sans pb-20">
    <!-- Header -->
    <header class="bg-white/80 backdrop-blur-md border-b border-gray-100 px-6 py-4 flex items-center justify-between sticky top-0 z-50">
        <div class="flex items-center space-x-4">
            <div class="bg-[#0d6a3d] p-2 rounded-xl shadow-lg shadow-[#0d6a3d]/20">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
            </div>
            <h1 class="text-xl font-black text-gray-900 tracking-tight">OurNovel <span class="text-[#0d6a3d]">Store</span></h1>
        </div>

        <div class="flex-1 max-w-xl mx-8 relative group hidden md:block">
            <input 
                type="text" 
                bind:value={search} 
                oninput={handleSearch}
                placeholder="Search authors, titles..." 
                class="w-full pl-10 pr-4 py-2.5 border-none rounded-xl bg-gray-50 focus:bg-white focus:ring-4 focus:ring-[#0d6a3d]/5 outline-none transition-all font-bold text-gray-700 placeholder-gray-300 shadow-inner"
            >
            <span class="absolute left-3.5 top-2.5 text-gray-300 group-focus-within:text-[#0d6a3d] transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </span>
        </div>

        <div class="flex items-center space-x-3">
            <button 
                onclick={() => showCart = !showCart}
                class="relative p-2.5 rounded-xl bg-gray-50 text-gray-600 hover:bg-[#0d6a3d]/5 hover:text-[#0d6a3d] transition-all"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
                {#if cartItems.length > 0}
                    <span class="absolute -top-1 -right-1 bg-[#0d6a3d] text-white text-[10px] font-black w-5 h-5 flex items-center justify-center rounded-full border-2 border-white shadow-sm">
                        {cartItems.length}
                    </span>
                {/if}
            </button>
            <div class="w-10 h-10 rounded-xl bg-[#0d6a3d]/5 flex items-center justify-center text-[#0d6a3d] font-black cursor-pointer hover:bg-[#0d6a3d]/10 transition-colors">
                JD
            </div>
        </div>
    </header>

    <main class="max-w-7xl mx-auto px-6 py-10">
        <!-- Authors Section -->
        <section class="mb-16">
            <div class="flex items-center justify-between mb-8">
                <h2 class="text-2xl font-black text-gray-900 tracking-tight uppercase">Featured Authors</h2>
                <div class="h-1 flex-1 ml-6 bg-gray-50 rounded-full"></div>
            </div>
            
            <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-6">
                <AuthorAvatar 
                    author={{ name: 'All', profile_image: null }} 
                    selected={selectedAuthorId === null} 
                    onclick={() => selectAuthor(null)} 
                />

                {#each authors as author}
                    <AuthorAvatar 
                        {author} 
                        selected={selectedAuthorId === author.id} 
                        onclick={() => selectAuthor(author.id)} 
                    />
                {/each}
            </div>
        </section>

        <!-- Books Section -->
        <section>
            <div class="flex items-center justify-between mb-8">
                <h2 class="text-2xl font-black text-gray-900 tracking-tight uppercase">
                    {#if selectedAuthorId}
                        Books by {authors.find(a => a.id === selectedAuthorId)?.name}
                    {:else}
                        Explore All Books
                    {/if}
                </h2>
                <select 
                    bind:value={selectedCategoryId} 
                    onchange={updateFilters}
                    class="ml-6 border-none rounded-xl px-4 py-2 bg-gray-50 hover:bg-gray-100 transition-colors font-bold text-sm text-gray-600 outline-none cursor-pointer"
                >
                    <option value={null}>All Categories</option>
                    {#each categories as category}
                        <option value={category.id}>{category.name}</option>
                    {/each}
                </select>
                <div class="h-1 flex-1 ml-6 bg-gray-50 rounded-full"></div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
                {#each books.data as book (book.id)}
                    <BookCard {book} />
                {:else}
                    <div class="col-span-full py-32 flex flex-col items-center justify-center text-gray-300">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 mb-4 opacity-20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332-4.5 1.253" />
                        </svg>
                        <p class="text-xl font-bold text-gray-400">No books found matching your selection.</p>
                    </div>
                {/each}
            </div>

            {#if books.last_page > 1}
                <div class="mt-16 flex justify-center space-x-3">
                     <button class="px-8 py-3 rounded-xl font-black bg-white border border-gray-100 text-gray-500 hover:bg-gray-50 transition-colors">Previous</button>
                     <button class="px-8 py-3 rounded-xl font-black bg-[#0d6a3d] text-white shadow-lg shadow-[#0d6a3d]/20 hover:bg-[#0b5933] transition-colors">Next Page</button>
                </div>
            {/if}
        </section>
    </main>

    <!-- Cart Sidebar Overlay -->
    {#if showCart}
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <!-- svelte-ignore a11y_no_static_element_interactions -->
        <div class="fixed inset-0 bg-black/40 backdrop-blur-sm z-[60] transition-opacity" onclick={() => showCart = false}></div>
        <aside class="fixed right-0 top-0 h-full w-full max-w-md bg-white shadow-2xl z-[70] flex flex-col transform transition-transform duration-300">
            <div class="p-6 border-b border-gray-50 flex items-center justify-between">
                <div>
                    <h2 class="text-xl font-black text-gray-900 tracking-tight uppercase">Your Cart</h2>
                    <p class="text-xs font-bold text-gray-400 mt-0.5 uppercase tracking-widest">{cartItems.length} Items Selected</p>
                </div>
                <button onclick={() => showCart = false} class="p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-400">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <div class="flex-1 overflow-y-auto p-6 space-y-6 custom-scrollbar">
                {#each cartItems as item (item.id)}
                    <CartItem {item} id={item.id} />
                {:else}
                    <div class="h-full flex flex-col items-center justify-center text-gray-300 py-12">
                        <div class="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mb-6 border-2 border-dashed border-gray-100">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 opacity-30" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                            </svg>
                        </div>
                        <p class="font-black text-gray-400 uppercase tracking-widest text-[10px]">Your cart is empty</p>
                    </div>
                {/each}
            </div>

            <div class="p-8 bg-gray-50/50 border-t border-gray-100 space-y-6">
                <div class="space-y-4">
                    <div class="flex justify-between items-center px-2">
                        <span class="text-lg font-black text-gray-900 uppercase tracking-tighter">Total Amount</span>
                        <span class="text-3xl font-black text-[#0d6a3d]">${subtotal.toFixed(2)}</span>
                    </div>
                </div>

                <button 
                    onclick={checkout}
                    disabled={cartItems.length === 0}
                    class="w-full bg-[#0d6a3d] hover:bg-[#0b5933] disabled:bg-gray-200 text-white text-lg font-black py-4 rounded-2xl shadow-xl shadow-[#0d6a3d]/10 transition-all active:scale-95 uppercase tracking-widest disabled:shadow-none"
                >
                    Proceed to Checkout
                </button>
            </div>
        </aside>
    {/if}

    <!-- Payment Modal -->
    {#if showPaymentModal}
        <div class="fixed inset-0 z-[100] flex items-center justify-center bg-gray-900/60 backdrop-blur-md p-6">
            <div class="bg-white rounded-[2.5rem] shadow-2xl max-w-lg w-full overflow-hidden border border-gray-100 p-8 text-center">
                <h3 class="text-2xl font-black text-gray-900 mb-2">Payment Verification</h3>
                <p class="text-gray-500 font-bold text-sm tracking-widest mb-8 uppercase">Scan QR to pay ${subtotal.toFixed(2)}</p>
                
                <div class="mb-8 p-8 bg-gray-50 rounded-[2rem] border-2 border-dashed border-gray-200 flex flex-col items-center">
                    {#if paymentStatus === 'pending'}
                        <img src={qrCodeUrl} alt="KHQR" class="w-56 h-56 bg-white p-3 rounded-2xl shadow-xl mb-6">
                        <div class="flex items-center space-x-3">
                            <span class="flex h-3 w-3">
                                <span class="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-[#0d6a3d] opacity-75"></span>
                                <span class="relative inline-flex rounded-full h-3 w-3 bg-[#0d6a3d]"></span>
                            </span>
                            <span class="text-[#0d6a3d] font-black uppercase text-[10px] tracking-widest animate-pulse">Waiting for Payment...</span>
                        </div>
                    {:else}
                        <div class="py-8 flex flex-col items-center">
                            <div class="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mb-4">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="4" d="M5 13l4 4L19 7" />
                                </svg>
                            </div>
                            <h4 class="text-2xl font-black text-green-600">Success!</h4>
                        </div>
                    {/if}
                </div>

                <div class="flex space-x-3">
                    <button onclick={closePaymentModal} class="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-600 font-black py-4 rounded-xl transition-all uppercase text-sm tracking-widest">
                        Close
                    </button>
                    {#if paymentStatus !== 'paid'}
                        <button class="flex-1 bg-[#0d6a3d]/5 text-[#0d6a3d] font-black py-4 rounded-xl hover:bg-[#0d6a3d]/10 transition-all uppercase text-sm tracking-widest">
                            Support
                        </button>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 6px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: transparent;
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: #f1f5f9;
        border-radius: 20px;
    }
    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: #e2e8f0;
    }
</style>
