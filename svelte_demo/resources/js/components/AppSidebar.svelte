<script lang="ts">
    import { Link } from '@inertiajs/svelte';
    import BookOpen from 'lucide-svelte/icons/book-open';
    import Building2 from 'lucide-svelte/icons/building-2';
    import Folder from 'lucide-svelte/icons/folder';
    import LayoutGrid from 'lucide-svelte/icons/layout-grid';
    import Users from 'lucide-svelte/icons/users';
    import type { Snippet } from 'svelte';
    import AppLogo from '@/components/AppLogo.svelte';
    import NavFooter from '@/components/NavFooter.svelte';
    import NavMain from '@/components/NavMain.svelte';
    import NavUser from '@/components/NavUser.svelte';
    import {
        Sidebar,
        SidebarContent,
        SidebarFooter,
        SidebarHeader,
        SidebarMenu,
        SidebarMenuButton,
        SidebarMenuItem,
    } from '@/components/ui/sidebar';
    import { toUrl } from '@/lib/utils';
    import type { NavItem } from '@/types';
    import { dashboard } from '@/routes';
    import categories from '@/routes/categories';
    import authors from '@/routes/authors';
    import publishers from '@/routes/publishers';
    import books from '@/routes/books';

    let {
        children,
    }: {
        children?: Snippet;
    } = $props();

    const mainNavItems: NavItem[] = [
        {
            title: 'Dashboard',
            href: dashboard(),
            icon: LayoutGrid,
        },
    ];

    const libraryNavItems: NavItem[] = [
        {
            title: 'Books',
            href: books.index(),
            icon: BookOpen,
        },
        {
            title: 'Authors',
            href: authors.index(),
            icon: Users,
        },
        {
            title: 'Publishers',
            href: publishers.index(),
            icon: Building2,
        },
        {
            title: 'Categories',
            href: categories.index(),
            icon: Folder,
        },
    ];

    const footerNavItems: NavItem[] = [
        {
            title: 'Github Repo',
            href: 'https://github.com/laravel/svelte-starter-kit',
            icon: Folder,
        },
        {
            title: 'Documentation',
            href: 'https://laravel.com/docs/starter-kits#svelte',
            icon: BookOpen,
        },
    ];
</script>

<Sidebar collapsible="icon" variant="inset">
    <SidebarHeader>
        <SidebarMenu>
                <SidebarMenuItem>
                    <SidebarMenuButton size="lg" asChild>
                        {#snippet children(props)}
                            <Link {...props} href={toUrl(dashboard())} class={props.class}>
                                <AppLogo />
                            </Link>
                        {/snippet}
                    </SidebarMenuButton>
                </SidebarMenuItem>
        </SidebarMenu>
    </SidebarHeader>

    <SidebarContent>
        <NavMain items={mainNavItems} title="Overview" />
        <NavMain items={libraryNavItems} title="Library Management" />
    </SidebarContent>

    <SidebarFooter>
        <NavFooter items={footerNavItems} />
        <NavUser />
    </SidebarFooter>
</Sidebar>
{@render children?.()}
