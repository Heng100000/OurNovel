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
        authors = [],
    }: {
        authors?: Array<{ id: number; name: string; bio: string; nationality: string }>;
    } = $props();

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: 'Authors',
            href: '/authors',
        },
    ];

    const form = useForm({
        name: '',
        bio: '',
        birth_date: '',
        nationality: '',
        website: '',
    });

    function addAuthor() {
        $form.post('/authors', {
            onSuccess: () => {
                form.reset();
            },
        });
    }
</script>

<AppHead title="Authors" />

<AppLayout {breadcrumbs}>
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-1">
            <Card>
                <CardHeader>
                    <CardTitle>Authors</CardTitle>
                    <CardDescription>Manage the people who write your books.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div class="grid gap-8 lg:grid-cols-[1fr_2fr]">
                        <!-- Action Side: Add Author Form -->
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <h3 class="text-lg font-medium">Add New Author</h3>
                                <p class="text-sm text-muted-foreground">Register a new author in the library system.</p>
                            </div>
                            
                            <form onsubmit={(e) => { e.preventDefault(); addAuthor(); }} class="grid gap-4">
                                <div class="grid gap-2">
                                    <Label for="name">Full Name</Label>
                                    <Input id="name" placeholder="Author name" bind:value={$form.name} required />
                                </div>
                                
                                <div class="grid grid-cols-2 gap-4">
                                    <div class="grid gap-2">
                                        <Label for="nationality">Nationality</Label>
                                        <Input id="nationality" placeholder="e.g. British" bind:value={$form.nationality} />
                                    </div>
                                    <div class="grid gap-2">
                                        <Label for="birth_date">Birth Date</Label>
                                        <Input id="birth_date" type="date" bind:value={$form.birth_date} />
                                    </div>
                                </div>
                                
                                <div class="grid gap-2">
                                    <Label for="website">Official Website</Label>
                                    <Input id="website" type="url" placeholder="https://..." bind:value={$form.website} />
                                </div>
                                
                                <div class="grid gap-2">
                                    <Label for="bio">Biography</Label>
                                    <Textarea id="bio" placeholder="Brief biography..." bind:value={$form.bio} class="min-h-[100px]" />
                                </div>
                                
                                <Button type="submit" disabled={$form.processing} class="w-full">
                                    {#if $form.processing}
                                        Adding...
                                    {:else}
                                        Register Author
                                    {/if}
                                </Button>
                            </form>
                        </div>

                        <!-- Data Side: Author List -->
                        <div class="space-y-6">
                            <div class="flex items-center justify-between">
                                <h3 class="text-lg font-medium">Registered Authors</h3>
                                <span class="rounded-full bg-secondary px-2.5 py-0.5 text-xs font-semibold">
                                    {authors.length} Total
                                </span>
                            </div>

                            <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-1">
                                {#if authors.length === 0}
                                    <div class="flex h-[200px] items-center justify-center rounded-lg border border-dashed text-sm text-muted-foreground">
                                        No authors registered yet.
                                    </div>
                                {:else}
                                    {#each authors as author (author.id)}
                                        <div class="flex items-start gap-4 rounded-lg border p-4 hover:bg-accent/50 transition-colors">
                                            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary font-bold">
                                                {author.name.charAt(0)}
                                            </div>
                                            <div class="flex-1 space-y-1">
                                                <div class="flex items-center justify-between">
                                                    <h4 class="font-semibold">{author.name}</h4>
                                                    {#if author.nationality}
                                                        <span class="text-[10px] uppercase tracking-wider text-muted-foreground bg-secondary px-1.5 py-0.5 rounded">
                                                            {author.nationality}
                                                        </span>
                                                    {/if}
                                                </div>
                                                {#if author.bio}
                                                    <p class="text-xs text-muted-foreground line-clamp-2">
                                                        {author.bio}
                                                    </p>
                                                {/if}
                                                <div class="flex items-center gap-3 pt-1">
                                                    {#if author.website}
                                                        <a href={author.website} target="_blank" class="text-[10px] text-primary hover:underline">
                                                            Visit Website
                                                        </a>
                                                    {/if}
                                                </div>
                                            </div>
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
