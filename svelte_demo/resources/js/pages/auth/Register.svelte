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
    import { login } from '@/routes';
    import { store } from '@/routes/register';
</script>

<AppHead title="Register" />

<AuthBase title="Create Account" description="Enter your details below to create your account">
    

    <Form
        {...store.form()}
        resetOnSuccess={['password', 'password_confirmation']}
    >
        {#snippet children({ errors, processing })}
            <div class="flex flex-col gap-6">
                <div>
                    <Label for="name">Full Name</Label>
                    <Input
                        id="name"
                        type="text"
                        required
                        autocomplete="name"
                        name="name"
                        placeholder="John Doe"
                    />
                    <InputError message={errors.name} class="input-error" />
                </div>

                <div>
                    <Label for="email">Email address</Label>
                    <Input
                        id="email"
                        type="email"
                        required
                        autocomplete="email"
                        name="email"
                        placeholder="your@email.com"
                    />
                    <InputError message={errors.email} class="input-error" />
                </div>

                <div>
                    <Label for="password">Password</Label>
                    <Input
                        id="password"
                        type="password"
                        required
                        autocomplete="new-password"
                        name="password"
                        placeholder="••••••••"
                    />
                    <InputError message={errors.password} class="input-error" />
                </div>

                <div>
                    <Label for="password_confirmation">Confirm Password</Label>
                    <Input
                        id="password_confirmation"
                        type="password"
                        required
                        autocomplete="new-password"
                        name="password_confirmation"
                        placeholder="••••••••"
                    />
                    <InputError message={errors.password_confirmation} class="input-error" />
                </div>

                <Button
                    type="submit"
                    disabled={processing}
                    data-test="register-user-button"
                    class="mt-2"
                >
                    {#if processing}<Spinner class="mr-2 h-4 w-4" />{/if}
                    Create account
                </Button>

                <div class="text-center text-[14px] text-gray-600 mt-2">
                    Already have an account? 
                    <TextLink href={login()} class="text-[#0d6a3d] font-bold hover:underline ml-1">Login</TextLink>
                </div>
            </div>
        {/snippet}
    </Form>
</AuthBase>
