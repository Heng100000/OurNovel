<script lang="ts">
    import type { Snippet } from 'svelte';
    import { fade } from 'svelte/transition';

    let {
        title = '',
        description = '',
        children,
    }: {
        title?: string;
        description?: string;
        children?: Snippet;
    } = $props();
</script>

<div class="auth-wrapper">
    <div class="auth-container" in:fade={{ duration: 400 }}>
        <div class="auth-header">
            <h1 class="auth-title">{title}</h1>
            <p class="auth-subtitle">{description}</p>
        </div>

        <div class="social-auth">
            <button class="social-button">
                <img src="https://www.svgrepo.com/show/475656/google-color.svg" alt="Google" />
            </button>
            <button class="social-button">
                <img src="https://www.svgrepo.com/show/475647/facebook-color.svg" alt="Facebook" />
            </button>
            <button class="social-button">
                <img src="https://www.svgrepo.com/show/353655/discord-icon.svg" alt="Discord" />
            </button>
        </div>

        <div class="auth-divider">
            <span>or</span>
        </div>

        <div class="auth-form-content">
            {@render children?.()}
        </div>
    </div>
</div>

<style>
    /* Premium Minimalist CSS */
    .auth-wrapper {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background-color: #ffffff;
        padding: 2rem;
        font-family: 'Inter', -apple-system, sans-serif;
    }

    .auth-container {
        width: 100%;
        max-width: 420px;
        animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
    }

    @keyframes slideUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .auth-header {
        text-align: center;
        margin-bottom: 2.5rem;
    }

    .auth-title {
        font-size: 2rem;
        font-weight: 800;
        color: #111827;
        margin-bottom: 0.5rem;
        letter-spacing: -0.025em;
    }

    .auth-subtitle {
        font-size: 1rem;
        color: #6b7280;
        line-height: 1.5;
    }

    .social-auth {
        display: flex;
        gap: 0.75rem;
        margin-bottom: 2rem;
    }

    .social-button {
        flex: 1;
        height: 56px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .social-button:hover {
        background: #f9fafb;
        border-color: #d1d5db;
        transform: translateY(-1px);
    }

    .social-button img {
        width: 24px;
        height: 24px;
    }

    .auth-divider {
        display: flex;
        align-items: center;
        margin-bottom: 2rem;
        color: #9ca3af;
        font-size: 0.875rem;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .auth-divider::before,
    .auth-divider::after {
        content: "";
        flex: 1;
        height: 1px;
        background-color: #e5e7eb;
    }

    .auth-divider span {
        padding: 0 1rem;
    }

    /* Global Overrides for Form Components */
    :global(.auth-form-content input) {
        width: 100% !important;
        height: 54px !important;
        padding: 0 1.25rem !important;
        background-color: #ffffff !important;
        border: 1.5px solid #e5e7eb !important;
        border-radius: 12px !important;
        font-size: 1rem !important;
        font-weight: 500 !important;
        color: #111827 !important;
        transition: all 0.2s ease !important;
        outline: none !important;
        box-shadow: none !important;
    }

    :global(.auth-form-content input:focus) {
        border-color: #0d6a3d !important;
        box-shadow: 0 0 0 4px rgba(13, 106, 61, 0.08) !important;
    }

    :global(.auth-form-content label) {
        display: block !important;
        margin-bottom: 0.5rem !important;
        font-size: 0.875rem !important;
        font-weight: 600 !important;
        color: #374151 !important;
    }

    :global(.auth-form-content button[type="submit"]) {
        width: 100% !important;
        height: 56px !important;
        background-color: #0d6a3d !important;
        color: #ffffff !important;
        border: none !important;
        border-radius: 12px !important;
        font-size: 1rem !important;
        font-weight: 700 !important;
        cursor: pointer !important;
        transition: all 0.2s ease !important;
        margin-top: 1rem !important;
        box-shadow: 0 10px 15px -3px rgba(13, 106, 61, 0.1) !important;
    }

    :global(.auth-form-content button[type="submit"]:hover) {
        background-color: #0b5933 !important;
        transform: translateY(-1px) !important;
        box-shadow: 0 20px 25px -5px rgba(13, 106, 61, 0.15) !important;
    }

    :global(.auth-form-content button[type="submit"]:active) {
        transform: scale(0.98) !important;
    }

    :global(.auth-form-content .input-error) {
        color: #ef4444 !important;
        font-size: 0.8125rem !important;
        margin-top: 0.5rem !important;
        font-weight: 500 !important;
    }

    :global(.auth-form-content a) {
        color: #0d6a3d !important;
        text-decoration: none !important;
        font-weight: 600 !important;
        transition: color 0.2s ease !important;
    }

    :global(.auth-form-content a:hover) {
        color: #0b5933 !important;
        text-decoration: underline !important;
    }

    :global(.auth-form-content .flex.flex-col.gap-6) {
        display: flex !important;
        flex-direction: column !important;
        gap: 1.5rem !important;
    }
</style>
