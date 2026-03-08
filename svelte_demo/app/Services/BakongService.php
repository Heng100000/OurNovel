<?php

namespace App\Services;

use App\Models\Payment;
use Illuminate\Support\Facades\Log;
use KHQR\BakongKHQR;
use KHQR\Helpers\KHQRData;
use KHQR\Models\IndividualInfo;

class BakongService
{
    protected string $token;

    protected string $accountId;

    protected string $merchantName;

    protected string $merchantCity;

    public function __construct()
    {
        $this->token = (string) config('services.bakong.token', '');
        $this->accountId = (string) config('services.bakong.account_id', '');
        $this->merchantName = (string) config('services.bakong.merchant_name', 'Shop');
        $this->merchantCity = (string) config('services.bakong.merchant_city', 'Phnom Penh');
    }

    /**
     * Generate a KHQR code string and MD5 hash for a payment.
     *
     * @return array{qr: string, md5: string}|null
     */
    public function generateQR(Payment $payment): ?array
    {
        try {
            $info = new IndividualInfo(
                $this->accountId,
                $this->merchantName,
                $this->merchantCity,
                null,      // acquiringBank
                null,      // accountInformation
                KHQRData::CURRENCY_USD,
                (float) $payment->amount,
                (string) $payment->order_id, // billNumber
            );

            $response = BakongKHQR::generateIndividual($info);

            if ($response->status['code'] !== 0) {
                Log::error('Bakong QR generation failed', $response->status);

                return null;
            }

            return [
                'qr' => $response->data['qr'],
                'md5' => $response->data['md5'],
            ];
        } catch (\Exception $e) {
            Log::error('Bakong generateQR exception', ['message' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * Generate a proper deep link (shortUrl) for the given KHQR string.
     */
    public function generateDeepLink(string $qrString): ?string
    {
        if (empty($this->token)) {
            return null;
        }

        try {
            $response = \Illuminate\Support\Facades\Http::withToken($this->token)
                ->withOptions([
                    'verify' => false,
                ])
                ->timeout(5)
                ->post('https://api-bakong.nbc.gov.kh/v1/generate_deeplink', [
                    'qr' => $qrString,
                    'appName' => $this->merchantName,
                ]);

            if ($response->successful()) {
                $data = $response->json();

                return $data['shortUrl'] ?? null;
            }

            Log::warning('Bakong DeepLink Request Failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return null;
        } catch (\Exception $e) {
            Log::error('Bakong generateDeepLink exception', ['message' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * Check if a transaction identified by MD5 has been paid.
     * checkTransactionByMD5 returns an array like:
     *   ['responseCode' => 0, 'data' => [...]] on success
     *   ['responseCode' => 1, ...] on not found / unpaid
     */
    public function checkTransactionByMD5(string $md5): array
    {
        if (empty($this->token)) {
            return ['success' => false, 'message' => 'Bakong token not configured'];
        }

        try {
            $response = \Illuminate\Support\Facades\Http::withToken($this->token)
                ->withHeaders([
                    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept' => 'application/json',
                ])
                ->withOptions(['verify' => false])
                ->timeout(10)
                ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
                    'md5' => $md5,
                ]);

            $result = $response->json();

            Log::info('Bakong MD5 Check Response', [
                'md5' => $md5,
                'status' => $response->status(),
                'response' => $result,
                'account_id' => $this->accountId,
            ]);

            if ($response->successful() && isset($result['responseCode']) && $result['responseCode'] === 0 && !empty($result['data'])) {
                Log::info('Bakong MD5 Check: PAID SUCCESS', ['id' => $md5]);
                return ['success' => true, 'message' => 'Paid'];
            }

            $msg = $result['responseMessage'] ?? ($result['message'] ?? 'Not found');
            return ['success' => false, 'message' => $msg];
        } catch (\Exception $e) {
            Log::error('Bakong MD5 check exception', ['message' => $e->getMessage()]);
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    /**
     * Fallback: Check if a transaction identified by billNumber has been paid.
     */
    /**
     * Fallback: Check if a transaction identified by external ref (Bill Number/Order ID) has been paid.
     */
    public function checkTransactionByBillNumber(string $billNumber): array
    {
        if (empty($this->token)) {
            return ['success' => false, 'message' => 'Bakong token not configured'];
        }

        try {
            $response = \Illuminate\Support\Facades\Http::withToken($this->token)
                ->withHeaders([
                    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept' => 'application/json',
                ])
                ->withOptions(['verify' => false])
                ->timeout(10)
                ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_external_ref', [
                    'externalRef' => $billNumber,
                ]);

            $result = $response->json();

            Log::info('Bakong External Ref Check Response', [
                'bill' => $billNumber,
                'status' => $response->status(),
                'response' => $result,
            ]);

            if ($response->successful() && isset($result['responseCode']) && $result['responseCode'] === 0 && !empty($result['data'])) {
                Log::info('Bakong External Ref Check: PAID SUCCESS', ['bill' => $billNumber]);
                return ['success' => true, 'message' => 'Paid'];
            }

            $msg = $result['responseMessage'] ?? ($result['message'] ?? 'Not found');
            return ['success' => false, 'message' => "Ref Check: $msg"];
        } catch (\Exception $e) {
            Log::error('Bakong bill check exception', ['message' => $e->getMessage()]);
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function getDebugInfo(): array
    {
        return [
            'account_id' => $this->accountId,
            'merchant_name' => $this->merchantName,
            'merchant_city' => $this->merchantCity,
            'has_token' => !empty($this->token),
            'token_snippet' => !empty($this->token) ? substr($this->token, 0, 10) . '...' : 'none',
        ];
    }

    /**
     * Build a QR code image URL using an external renderer.
     */
    public function getQrImageUrl(string $qrString): string
    {
        return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data='.urlencode($qrString);
    }
}
