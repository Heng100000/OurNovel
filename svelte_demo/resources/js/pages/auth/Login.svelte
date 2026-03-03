<script lang="ts">
    import { Form } from '@inertiajs/svelte';
    import AppHead from '@/components/AppHead.svelte';
    import InputError from '@/components/InputError.svelte';
    import TextLink from '@/components/TextLink.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import { Label } from '@/components/ui/label';
    import { Spinner } from '@/components/ui/spinner';
    import AuthBase from '@/layouts/AuthLayout.svelte';
    import { register } from '@/routes';
    import { store } from '@/routes/login';
    import { request } from '@/routes/password';
    import { fade } from 'svelte/transition';

    let {
        status = '',
        canResetPassword,
        canRegister,
    }: {
        status?: string;
        canResetPassword: boolean;
        canRegister: boolean;
    } = $props();
</script>

<AppHead title="Log in" />

<AuthBase title="Welcome Back" description="Enter your credentials to access your account">
    {#if status}
        <div class="mb-6 p-4 bg-green-50 rounded-xl text-center text-sm font-medium text-green-600 border border-green-100" in:fade>
            {status}
        </div>
    {/if}


    <Form
        {...store.form()}
        resetOnSuccess={['password']}
    >
        {#snippet children({ errors, processing })}
            <div class="flex flex-col gap-6">
                <div>
                    <Label for="email">Email address</Label>
                    <Input
                        id="email"
                        type="email"
                        name="email"
                        required
                        autocomplete="email"
                        placeholder="your@email.com"
                    />
                    <InputError message={errors.email} class="input-error" />
                </div>

                <div>
                    <div class="flex items-center justify-between mb-2">
                        <Label for="password" class="!mb-0">Password</Label>
                        {#if canResetPassword}
                            <TextLink href={request()} class="text-[14px] font-medium text-[#0d6a3d] hover:underline">
                                Forgot password?
                            </TextLink>
                        {/if}
                    </div>
                    <div class="relative group">
                        <Input
                            id="password"
                            type="password"
                            name="password"
                            required
                            autocomplete="current-password"
                            placeholder="••••••••"
                        />
                        <button type="button" class="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                            <svg xmlns="http://www.w3.org/2000/svg" class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                        </button>
                    </div>
                    <InputError message={errors.password} class="input-error" />
                </div>

                <Button
                    type="submit"
                    disabled={processing}
                    data-test="login-button"
                >
                    {#if processing}<Spinner class="mr-2 h-4 w-4" />{/if}
                    Login
                </Button>

                {#if canRegister}
                    <div class="text-center text-[14px] text-gray-600 mt-2">
                        Need an account? 
                        <TextLink href={register()} class="text-[#0d6a3d] font-bold hover:underline ml-1">Create account</TextLink>
                    </div>
                {/if}
            </div>
        {/snippet}
    </Form>
</AuthBase>
