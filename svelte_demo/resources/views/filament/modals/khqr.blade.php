<style>
@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&display=swap');

:root {
    --g-main:   #12693f;
    --g-dark:   #0d5233;
    --g-light:  #e8f5ee;
    --g-mid:    #d1ead9;
    --g-text:   #0a3d25;
}

.khqr-wrap {
    font-family: 'Nunito', system-ui, sans-serif;
    width: 100%;
}

/* ─── Header ─── */
.khqr-header {
    background: linear-gradient(145deg, var(--g-main) 0%, var(--g-dark) 100%);
    margin: -24px -24px 0 -24px;
    padding: 28px 24px 36px;
    border-radius: 4px 4px 0 0;
    text-align: center;
    position: relative;
    overflow: hidden;
}
.khqr-header::before {
    content: '';
    position: absolute; top: -40px; right: -40px;
    width: 130px; height: 130px; border-radius: 50%;
    background: rgba(255,255,255,.08);
}
.khqr-header::after {
    content: '';
    position: absolute; bottom: -30px; left: -20px;
    width: 90px; height: 90px; border-radius: 50%;
    background: rgba(255,255,255,.06);
}
.khqr-header-emoji { font-size: 34px; display: block; margin-bottom: 12px; }
.khqr-header-label {
    font-size: 11px; font-weight: 700; letter-spacing: .12em;
    text-transform: uppercase; color: rgba(255,255,255,.7); margin-bottom: 6px;
}
.khqr-header-amount {
    font-size: 40px; font-weight: 900; color: #fff; line-height: 1;
}
.khqr-header-id { font-size: 12px; color: rgba(255,255,255,.65); margin-top: 6px; font-weight: 600; }

/* ─── Body ─── */
.khqr-body {
    background: #fff;
    border: 1.5px solid var(--g-mid);
    border-top: none;
    border-radius: 0 0 16px 16px;
    padding: 24px 20px 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 18px;
    box-shadow: 0 6px 24px rgba(18,105,63,.1);
}

/* ─── QR ─── */
.khqr-qr-wrap { position: relative; }
.khqr-qr-card {
    padding: 12px; background: #fff;
    border-radius: 16px;
    box-shadow: 0 4px 16px rgba(18,105,63,.12), 0 0 0 1.5px var(--g-mid);
}
.khqr-qr-card img { display: block; border-radius: 8px; }

.khqr-live-badge {
    position: absolute; top: -10px; right: -10px;
    background: var(--g-main); color: #fff;
    font-size: 10px; font-weight: 800; letter-spacing: .06em;
    padding: 4px 10px; border-radius: 99px;
    display: flex; align-items: center; gap: 5px;
    box-shadow: 0 3px 10px rgba(18,105,63,.4);
}
.khqr-live-dot {
    width: 7px; height: 7px; border-radius: 50%; background: #fff;
    animation: khqr-pulse 1.4s ease-in-out infinite;
}
@keyframes khqr-pulse {
    0%,100% { opacity: 1; transform: scale(1); }
    50% { opacity: .4; transform: scale(1.6); }
}

/* ─── Banks ─── */
.khqr-banks {
    width: 100%; background: var(--g-light);
    border: 1.5px solid var(--g-mid);
    border-radius: 14px; padding: 14px 16px;
}
.khqr-banks-label {
    text-align: center; font-size: 10px; font-weight: 800;
    letter-spacing: .1em; text-transform: uppercase;
    color: var(--g-main); margin-bottom: 12px;
}
.khqr-banks-row { display: flex; justify-content: center; gap: 28px; }
.khqr-bank { display: flex; flex-direction: column; align-items: center; gap: 6px; }
.khqr-bank-icon {
    width: 44px; height: 44px; border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    font-size: 14px; font-weight: 900; color: #fff;
    box-shadow: 0 4px 10px rgba(0,0,0,.14);
    transition: transform .15s;
}
.khqr-bank-icon:hover { transform: translateY(-2px); }
.khqr-bank-name { font-size: 11px; font-weight: 700; color: var(--g-text); }

/* ─── Status ─── */
.khqr-status {
    width: 100%; display: flex; align-items: center; justify-content: center; gap: 10px;
    padding: 12px 16px;
    background: var(--g-light); border: 1.5px solid var(--g-mid);
    border-radius: 12px;
}
.khqr-status-text { font-size: 13px; color: var(--g-main); font-weight: 700; }
.khqr-spinner {
    width: 16px; height: 16px; flex-shrink: 0;
    border: 2.5px solid var(--g-mid); border-top-color: var(--g-main);
    border-radius: 50%; animation: khqr-spin .75s linear infinite;
}
@keyframes khqr-spin { to { transform: rotate(360deg); } }

/* ─── Ref ─── */
.khqr-ref {
    font-size: 10px; font-family: 'Courier New', monospace;
    color: #b0bec5; word-break: break-all; text-align: center;
    max-width: 280px; line-height: 1.5;
}

/* ─── Success ─── */
.khqr-success {
    display: flex; flex-direction: column; align-items: center;
    justify-content: center; padding: 48px 24px; gap: 14px; text-align: center;
    animation: khqr-pop .5s cubic-bezier(.34,1.56,.64,1) both;
}
@keyframes khqr-pop {
    from { opacity: 0; transform: scale(.85); }
    to   { opacity: 1; transform: scale(1); }
}
.khqr-success-icon {
    width: 90px; height: 90px; border-radius: 50%;
    background: linear-gradient(145deg, #34d399, var(--g-main));
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 8px 28px rgba(18,105,63,.3);
    animation: khqr-bounce .55s .1s cubic-bezier(.34,1.56,.64,1) both;
}
@keyframes khqr-bounce { from { transform: scale(0); } to { transform: scale(1); } }
.khqr-success-icon svg { width: 48px; height: 48px; }
.khqr-success-title { font-size: 22px; font-weight: 900; color: var(--g-text); }
.khqr-success-sub { font-size: 13px; color: #90a4ae; font-weight: 600; }
.khqr-confetti { font-size: 30px; }

/* ─── Error ─── */
.khqr-error {
    display: flex; flex-direction: column; align-items: center;
    justify-content: center; padding: 48px 24px; gap: 10px; text-align: center;
}
.khqr-error-icon { font-size: 40px; }
.khqr-error-title { font-size: 17px; font-weight: 800; color: #263238; margin-top: 4px; }
.khqr-error-sub { font-size: 13px; color: #90a4ae; font-weight: 600; max-width: 220px; line-height: 1.6; }
</style>

<div class="khqr-wrap" x-data="{
    paid: false,
    poll() {
        let t = setInterval(async () => {
            if (this.paid) { clearInterval(t); return; }
            try {
                const r = await fetch('/api/payments/{{ $paymentId }}/check-bakong');
                const d = await r.json();
                if (d.paid) { this.paid = true; clearInterval(t); setTimeout(() => window.location.reload(), 2000); }
            } catch(e) {}
        }, 3000);
    }
}" x-init="poll()">

    {{-- SUCCESS --}}
    <template x-if="paid">
        <div class="khqr-success">
            <div class="khqr-confetti">🎉</div>
            <div class="khqr-success-icon">
                <svg fill="none" stroke="white" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
                </svg>
            </div>
            <div class="khqr-success-title">Payment Received!</div>
            <div class="khqr-success-sub">Refreshing in a moment... ✨</div>
        </div>
    </template>

    {{-- WAITING --}}
    <template x-if="!paid">
        <div>
            @if($imageUrl)
                <div class="khqr-header">
                    <span class="khqr-header-emoji">📲</span>
                    <div class="khqr-header-label">Amount to Pay</div>
                    <div class="khqr-header-amount">${{ number_format((float) $amount, 2) }}</div>
                    <div class="khqr-header-id">Payment #{{ $paymentId }}</div>
                </div>

                <div class="khqr-body">
                    <div class="khqr-qr-wrap">
                        <div class="khqr-qr-card">
                            <img src="{{ $imageUrl }}" alt="KHQR Code" width="220" height="220" />
                        </div>
                        <div class="khqr-live-badge">
                            <span class="khqr-live-dot"></span> LIVE
                        </div>
                    </div>

                    <div class="khqr-banks">
                        <div class="khqr-banks-label">Scan with your bank app</div>
                        <div class="khqr-banks-row">
                            <div class="khqr-bank">
                                <div class="khqr-bank-icon" style="background:linear-gradient(135deg,#1e40af,#3b82f6)">B</div>
                                <span class="khqr-bank-name">Bakong</span>
                            </div>
                            <div class="khqr-bank">
                                <div class="khqr-bank-icon" style="background:linear-gradient(135deg,#b91c1c,#ef4444)">A</div>
                                <span class="khqr-bank-name">ABA</span>
                            </div>
                            <div class="khqr-bank">
                                <div class="khqr-bank-icon" style="background:linear-gradient(135deg,#b45309,#f59e0b)">AC</div>
                                <span class="khqr-bank-name">ACLEDA</span>
                            </div>
                        </div>
                    </div>

                    <div class="khqr-status">
                        <div class="khqr-spinner"></div>
                        <span class="khqr-status-text">Waiting for your payment…</span>
                    </div>

                    @if($md5)
                        <p class="khqr-ref">Ref: {{ $md5 }}</p>
                    @endif
                </div>
            @else
                <div class="khqr-error">
                    <div class="khqr-error-icon">😕</div>
                    <div class="khqr-error-title">Couldn't load QR</div>
                    <div class="khqr-error-sub">Please close and try again, or check your Bakong settings.</div>
                </div>
            @endif
        </div>
    </template>
</div>