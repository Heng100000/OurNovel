<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
    import AppHead from '@/components/AppHead.svelte';
    import AppLayout from '@/layouts/AppLayout.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import { Label } from '@/components/ui/label';
    import {
        Card,
        CardHeader,
        CardTitle,
        CardDescription,
        CardContent,
    } from '@/components/ui/card';
    import type { BreadcrumbItem } from '@/types';

    let {
        publishers = [],
    }: {
        publishers?: Array<{ id: number; name: string; address: string; website: string; contact_email: string }>;
    } = $props();

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: 'Publishers',
            href: '/publishers',
        },
    ];

    const form = useForm({
        name: '',
        address: '',
        website: '',
        contact_email: '',
    });

    function addPublisher() {
        $form.post('/publishers', {
            onSuccess: () => {
                form.reset();
            },
        });
    }
</script>

<AppHead title="Publishers" />

<AppLayout {breadcrumbs}>
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-1">
            <Card>
                <CardHeader>
                    <CardTitle>Publishers</CardTitle>
                    <CardDescription>Manage book publishing houses.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div class="grid gap-8 lg:grid-cols-[1fr_2fr]">
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <h3 class="text-lg font-medium">Add New Publisher</h3>
                                <p class="text-sm text-muted-foreground">Add a new publishing house to your directory.</p>
                            </div>

                            <form onsubmit={(e) => { e.preventDefault(); addPublisher(); }} class="grid gap-4">
                                <div class="grid gap-2">
                                    <Label for="name">Company Name</Label>
                                    <Input id="name" placeholder="Publisher name" bind:value={$form.name} required />
                                </div>
                                <div class="grid gap-2">
                                    <Label for="address">Address</Label>
                                    <Input id="address" placeholder="Physical address" bind:value={$form.address} />
                                </div>
                                <div class="grid grid-cols-2 gap-4">
                                    <div class="grid gap-2">
                                        <Label for="website">Website</Label>
                                        <Input id="website" type="url" placeholder="https://..." bind:value={$form.website} />
                                    </div>
                                    <div class="grid gap-2">
                                        <Label for="email">Contact Email</Label>
                                        <Input id="email" type="email" placeholder="contact@publisher.com" bind:value={$form.contact_email} />
                                    </div>
                                </div>
                                <Button type="submit" disabled={$form.processing} class="w-full">
                                    { $form.processing ? 'Adding...' : 'Add Publisher' }
                                </Button>
                            </form>
                        </div>

                        <div class="space-y-6">
                            <h3 class="text-lg font-medium">Publishers Directory</h3>
                            
                            <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-1">
                                {#if publishers.length === 0}
                                    <div class="flex h-[200px] items-center justify-center rounded-lg border border-dashed text-sm text-muted-foreground">
                                        No publishers added yet.
                                    </div>
                                {:else}
                                    {#each publishers as publisher (publisher.id)}
                                        <div class="flex items-center justify-between rounded-lg border p-4 bg-card shadow-sm hover:bg-accent/50 transition-colors">
                                            <div class="space-y-1">
                                                <h4 class="font-bold">{publisher.name}</h4>
                                                {#if publisher.address}
                                                    <p class="text-xs text-muted-foreground flex items-center gap-1">
                                                        <span class="opacity-70">📍</span> {publisher.address}
                                                    </p>
                                                {:else}
                                                    <p class="text-[10px] text-muted-foreground italic">No address provided</p>
                                                {/if}
                                            </div>
                                            <div class="flex flex-col items-end gap-1.5">
                                                {#if publisher.website}
                                                    <a href={publisher.website} target="_blank" class="text-[10px] text-primary hover:underline font-medium">
                                                        Official Website
                                                    </a>
                                                {/if}
                                                {#if publisher.contact_email}
                                                    <span class="text-[10px] text-muted-foreground border border-muted-foreground/20 px-1.5 py-0.5 rounded-full">
                                                        {publisher.contact_email}
                                                    </span>
                                                {/if}
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
