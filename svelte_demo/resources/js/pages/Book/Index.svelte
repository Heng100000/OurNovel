<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
    import BookOpen from 'lucide-svelte/icons/book-open';
    import AppHead from '@/components/AppHead.svelte';
    import AppLayout from '@/layouts/AppLayout.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import { Label } from '@/components/ui/label';
    import { Textarea } from '@/components/ui/textarea';
    import {
        Card,
        CardHeader,
        CardTitle,
        CardDescription,
        CardContent,
    } from '@/components/ui/card';
    import type { BreadcrumbItem } from '@/types';

    let {
        books = [],
        categories = [],
        authors = [],
        publishers = [],
    }: {
        books?: Array<{ 
            id: number; 
            title: string; 
            slug: string;
            isbn: string;
            price: number;
            author: { name: string }; 
            category: { name: string };
            publisher: { name: string };
        }>;
        categories?: Array<{ id: number; name: string }>;
        authors?: Array<{ id: number; name: string }>;
        publishers?: Array<{ id: number; name: string }>;
    } = $props();

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: 'Books',
            href: '/books',
        },
    ];

    const form = useForm({
        title: '',
        slug: '',
        isbn: '',
        description: '',
        published_at: '',
        price: '',
        page_count: '',
        language: 'English',
        author_id: '',
        category_id: '',
        publisher_id: '',
    });

    function addBook() {
        $form.post('/books', {
            onSuccess: () => {
                form.reset();
            },
        });
    }

    // Auto-generate slug from title
    $effect(() => {
        if ($form.title && !$form.slug) {
            $form.slug = $form.title.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '');
        }
    });

    const selectClass = "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50";
</script>

<AppHead title="Books" />

<AppLayout {breadcrumbs}>
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-1">
            <Card>
                <CardHeader>
                    <CardTitle>Books</CardTitle>
                    <CardDescription>Manage your detailed book collection.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div class="grid gap-8 lg:grid-cols-[1fr_2fr]">
                        <!-- Form Column -->
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <h3 class="text-lg font-medium">Register New Book</h3>
                                <p class="text-sm text-muted-foreground">Fill in the technical and descriptive details of the book.</p>
                            </div>

                            <form onsubmit={(e) => { e.preventDefault(); addBook(); }} class="grid gap-4">
                                <div class="grid gap-2">
                                    <Label for="title">Title</Label>
                                    <Input id="title" placeholder="Book title" bind:value={$form.title} required />
                                </div>
                                <div class="grid gap-2">
                                    <Label for="slug">URL Slug</Label>
                                    <Input id="slug" placeholder="book-slug" bind:value={$form.slug} required />
                                </div>

                                <div class="grid grid-cols-2 gap-4">
                                    <div class="grid gap-2">
                                        <Label for="isbn">ISBN</Label>
                                        <Input id="isbn" placeholder="ISBN-13" bind:value={$form.isbn} />
                                    </div>
                                    <div class="grid gap-2">
                                        <Label for="price">Price ($)</Label>
                                        <Input id="price" type="number" step="0.01" placeholder="0.00" bind:value={$form.price} />
                                    </div>
                                </div>

                                <div class="grid gap-2">
                                    <Label for="published_at">Published Date</Label>
                                    <Input id="published_at" type="date" bind:value={$form.published_at} />
                                </div>

                                <div class="space-y-4 pt-2">
                                    <div class="grid gap-2">
                                        <Label for="author">Select Author</Label>
                                        <select id="author" bind:value={$form.author_id} class={selectClass} required>
                                            <option value="">-- Choose Author --</option>
                                            {#each authors as author}
                                                <option value={author.id}>{author.name}</option>
                                            {/each}
                                        </select>
                                    </div>
                                    <div class="grid gap-2">
                                        <Label for="publisher">Select Publisher</Label>
                                        <select id="publisher" bind:value={$form.publisher_id} class={selectClass} required>
                                            <option value="">-- Choose Publisher --</option>
                                            {#each publishers as publisher}
                                                <option value={publisher.id}>{publisher.name}</option>
                                            {/each}
                                        </select>
                                    </div>
                                    <div class="grid gap-2">
                                        <Label for="category">Select Genre/Category</Label>
                                        <select id="category" bind:value={$form.category_id} class={selectClass} required>
                                            <option value="">-- Choose Category --</option>
                                            {#each categories as category}
                                                <option value={category.id}>{category.name}</option>
                                            {/each}
                                        </select>
                                    </div>
                                </div>

                                <div class="grid gap-2">
                                    <Label for="description">Summary/Description</Label>
                                    <Textarea id="description" placeholder="Brief book summary..." bind:value={$form.description} class="min-h-[120px]" />
                                </div>

                                <Button type="submit" disabled={$form.processing} class="w-full">
                                    { $form.processing ? 'Registering...' : 'Add to Collection' }
                                </Button>
                            </form>
                        </div>

                        <!-- Table/List Column -->
                        <div class="space-y-6">
                            <div class="flex items-center justify-between">
                                <h3 class="text-lg font-medium">Library Collection</h3>
                                <div class="flex items-center gap-2 text-xs text-muted-foreground bg-accent px-3 py-1 rounded-full border">
                                    <span class="inline-block h-2 w-2 rounded-full bg-green-500 animate-pulse"></span>
                                    {books.length} Active Records
                                </div>
                            </div>

                            <div class="grid gap-4">
                                {#if books.length === 0}
                                    <div class="flex h-[400px] flex-col items-center justify-center rounded-xl border border-dashed text-center">
                                        <BookOpen class="h-10 w-10 text-muted/30 mb-2" />
                                        <p class="text-sm font-medium text-muted-foreground">Your library is empty</p>
                                        <p class="text-xs text-muted-foreground/60 max-w-[200px]">Use the form to add your first book to the collection.</p>
                                    </div>
                                {:else}
                                    <div class="rounded-lg border bg-card">
                                        <div class="grid grid-cols-[1fr_auto] gap-4 p-4 font-semibold text-xs text-muted-foreground border-b bg-muted/30 uppercase tracking-wider">
                                            <span>Technical & Meta Info</span>
                                            <span class="text-right">Price</span>
                                        </div>
                                        <div class="divide-y max-h-[800px] overflow-y-auto">
                                            {#each books as book (book.id)}
                                                <div class="p-5 hover:bg-accent/30 transition-colors group">
                                                    <div class="flex justify-between items-start mb-3">
                                                        <div class="space-y-1">
                                                            <h4 class="font-bold text-lg group-hover:text-primary transition-colors">{book.title}</h4>
                                                            <div class="flex items-center gap-2 text-[10px] text-muted-foreground font-mono">
                                                                <span class="bg-secondary px-1 py-0.5 rounded">ISBN: {book.isbn || 'N/A'}</span>
                                                                {#if book.slug}
                                                                    <span class="opacity-40">|</span>
                                                                    <span>/{book.slug}</span>
                                                                {/if}
                                                            </div>
                                                        </div>
                                                        <div class="text-right">
                                                            <p class="text-lg font-bold">${book.price || '0.00'}</p>
                                                            <p class="text-[10px] text-muted-foreground uppercase font-medium">MSRP</p>
                                                        </div>
                                                    </div>

                                                    <div class="grid grid-cols-3 gap-2 pt-2">
                                                        <div class="rounded bg-blue-50 dark:bg-blue-900/20 p-2 border border-blue-100 dark:border-blue-800/50">
                                                            <p class="text-[9px] uppercase font-bold text-blue-600 dark:text-blue-400 mb-1">Author</p>
                                                            <p class="text-[11px] font-semibold truncate">{book.author?.name || 'Unknown'}</p>
                                                        </div>
                                                        <div class="rounded bg-purple-50 dark:bg-purple-900/20 p-2 border border-purple-100 dark:border-purple-800/50">
                                                            <p class="text-[9px] uppercase font-bold text-purple-600 dark:text-purple-400 mb-1">Genre</p>
                                                            <p class="text-[11px] font-semibold truncate">{book.category?.name || 'Uncategorized'}</p>
                                                        </div>
                                                        <div class="rounded bg-emerald-50 dark:bg-emerald-900/20 p-2 border border-emerald-100 dark:border-emerald-800/50">
                                                            <p class="text-[9px] uppercase font-bold text-emerald-600 dark:text-emerald-400 mb-1">Publisher</p>
                                                            <p class="text-[11px] font-semibold truncate">{book.publisher?.name || 'Unknown'}</p>
                                                        </div>
                                                    </div>

                                                    {#if book.description}
                                                        <div class="mt-4 pt-3 border-t border-dashed">
                                                            <p class="text-[11px] text-muted-foreground leading-relaxed italic line-clamp-2">
                                                                "{book.description}"
                                                            </p>
                                                        </div>
                                                    {/if}
                                                </div>
                                            {/each}
                                        </div>
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    </div>
</AppLayout>
