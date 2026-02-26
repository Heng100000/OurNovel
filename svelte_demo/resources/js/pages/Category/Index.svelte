<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
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
        categories = [],
    }: {
        categories?: Array<{ id: number; name: string; slug: string; description: string }>;
    } = $props();

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: 'Categories',
            href: '/categories',
        },
    ];

    const form = useForm({
        name: '',
        slug: '',
        description: '',
    });

    function addCategory() {
        $form.post('/categories', {
            onSuccess: () => {
                form.reset();
            },
        });
    }

    // Auto-generate slug from name
    $effect(() => {
        if ($form.name && !$form.slug) {
            $form.slug = $form.name.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '');
        }
    });
</script>

<AppHead title="Categories" />

<AppLayout {breadcrumbs}>
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-1">
            <Card>
                <CardHeader>
                    <CardTitle>Categories</CardTitle>
                    <CardDescription>Organize your books into categories.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div class="grid gap-8 lg:grid-cols-[1fr_2fr]">
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <h3 class="text-lg font-medium">Add Category</h3>
                                <p class="text-sm text-muted-foreground">Define a new genre or topic for books.</p>
                            </div>

                            <form onsubmit={(e) => { e.preventDefault(); addCategory(); }} class="grid gap-4">
                                <div class="grid gap-2">
                                    <Label for="name">Name</Label>
                                    <Input id="name" type="text" placeholder="e.g. Science Fiction" bind:value={$form.name} required />
                                </div>
                                <div class="grid gap-2">
                                    <Label for="slug">URL Slug</Label>
                                    <Input id="slug" type="text" placeholder="e.g. science-fiction" bind:value={$form.slug} required />
                                </div>
                                <div class="grid gap-2">
                                    <Label for="description">Description</Label>
                                    <Textarea id="description" placeholder="Brief genre description..." bind:value={$form.description} class="min-h-[100px]" />
                                </div>
                                <Button type="submit" disabled={$form.processing} class="w-full">
                                    { $form.processing ? 'Adding...' : 'Add Genre' }
                                </Button>
                            </form>
                        </div>

                        <div class="space-y-6">
                            <h3 class="text-lg font-medium">Available Genres</h3>

                            <div class="grid gap-4 md:grid-cols-2">
                                {#if categories.length === 0}
                                    <div class="col-span-2 flex h-[200px] items-center justify-center rounded-lg border border-dashed text-sm text-muted-foreground">
                                        No categories defined yet.
                                    </div>
                                {:else}
                                    {#each categories as category (category.id)}
                                        <div class="flex flex-col rounded-lg border p-5 space-y-3 bg-secondary/10 hover:border-primary/50 transition-colors cursor-default group">
                                            <div class="flex justify-between items-start">
                                                <h4 class="font-bold group-hover:text-primary transition-colors">{category.name}</h4>
                                                <code class="text-[9px] bg-secondary px-1.5 py-0.5 rounded text-muted-foreground">/{category.slug}</code>
                                            </div>
                                            {#if category.description}
                                                <p class="text-xs text-muted-foreground leading-relaxed line-clamp-2">
                                                    {category.description}
                                                </p>
                                            {:else}
                                                <p class="text-[10px] text-muted-foreground italic">No description</p>
                                            {/if}
                                        </div>
                                    {/each}
                                {/if}
                            </div>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    </div>
</AppLayout>
