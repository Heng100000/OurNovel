<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
    import AppHead from '@/components/AppHead.svelte';
    import AppLayout from '@/layouts/AppLayout.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import {
        Card,
        CardHeader,
        CardTitle,
        CardDescription,
        CardContent,
    } from '@/components/ui/card';
    import type { BreadcrumbItem } from '@/types';

    export let tasks: Array<{ id: number; title: string }> = [];

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: 'Tasks',
            href: '/',
        },
    ];

    const form = useForm({
        title: '',
    });

    function addTask() {
        $form.post('/tasks', {
            onSuccess: () => {
                form.reset('title');
            },
        });
    }
</script>

<AppHead title="Tasks" />

<AppLayout {breadcrumbs}>
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="grid auto-rows-min gap-4 md:grid-cols-1">
            <Card>
                <CardHeader>
                    <CardTitle>My Tasks</CardTitle>
                    <CardDescription>Manage your daily tasks.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form on:submit|preventDefault={addTask} class="flex w-full max-w-sm items-center space-x-2 mb-6">
                        <Input type="text" placeholder="Add a new task..." bind:value={$form.title} />
                        <Button type="submit" disabled={$form.processing}>Add</Button>
                    </form>

                    <div class="space-y-2">
                        {#if tasks.length === 0}
                            <p class="text-sm text-muted-foreground">No tasks yet.</p>
                        {:else}
                            {#each tasks as task (task.id)}
                                <div class="flex items-center justify-between rounded-md border p-2">
                                    <span class="text-sm">{task.title}</span>
                                </div>
                            {/each}
                        {/if}
                    </div>
                </CardContent>
            </Card>
        </div>
    </div>
</AppLayout>