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
    public function checkTransactionByMD5(string $md5): bool
    {
        if (empty($this->token)) {
            Log::error('Bakong token is not configured.');

            return false;
        }

        try {
            // Using Laravel Http facade to have control over SSL verification
            $response = \Illuminate\Support\Facades\Http::withToken($this->token)
                ->withOptions([
                    'verify' => false,
                ])
                ->timeout(5)
                ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
                    'md5' => $md5,
                    'accountId' => $this->accountId,
                ]);

            Log::info('Bakong MD5 Check Raw Response', [
                'id' => $md5,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            if ($response->successful()) {
                $data = $response->json();

                return isset($data['responseCode'])
                    && $data['responseCode'] === 0
                    && ! empty($data['data']);
            }

            return false;
        } catch (\Exception $e) {
            Log::error('Bakong MD5 check exception', ['message' => $e->getMessage()]);

            return false;
        }
    }

    /**
     * Fallback: Check if a transaction identified by billNumber has been paid.
     */
    public function checkTransactionByBillNumber(string $billNumber): bool
    {
        if (empty($this->token)) {
            return false;
        }

        try {
            $response = \Illuminate\Support\Facades\Http::withToken($this->token)
                ->withOptions(['verify' => false])
                ->timeout(5)
                ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_bill_number', [
                    'billNumber' => $billNumber,
                    'accountId' => $this->accountId,
                ]);

            Log::info('Bakong Bill Check Raw Response', [
                'bill' => $billNumber,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            if ($response->successful()) {
                $data = $response->json();

                return isset($data['responseCode'])
                    && $data['responseCode'] === 0
                    && ! empty($data['data']);
            }

            return false;
        } catch (\Exception $e) {
            Log::error('Bakong bill check exception', ['message' => $e->getMessage()]);

            return false;
        }
    }

    /**
     * Build a QR code image URL using an external renderer.
     */
    public function getQrImageUrl(string $qrString): string
    {
        return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data='.urlencode($qrString);
    }
}
