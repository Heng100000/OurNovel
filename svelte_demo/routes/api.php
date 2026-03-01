<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AuthorController;
use App\Http\Controllers\Api\BookController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\HealthCheckController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PromotionController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\SocialAuthController;
use App\Http\Controllers\TelegramWebhookController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/telegram/webhook', [TelegramWebhookController::class, 'handle']);

// Public: triggered by QR code scan — sends the invoice PDF to user's linked Telegram
Route::get('/invoices/send-telegram/{invoiceNo}', [\App\Http\Controllers\Api\InvoiceTelegramController::class, 'send']);

Route::get('/health', HealthCheckController::class);

Route::apiResource('categories', CategoryController::class);
Route::apiResource('authors', AuthorController::class);
Route::apiResource('books', BookController::class);
Route::patch('books/{book?}', [BookController::class, 'update']);

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/google/login', [SocialAuthController::class, 'loginWithGoogle']);
Route::post('/auth/facebook/login', [SocialAuthController::class, 'loginWithFacebook']);

Route::apiResource('delivery-companies', \App\Http\Controllers\Api\DeliveryCompanyController::class)->only(['index', 'show']);
Route::apiResource('reviews', ReviewController::class)->only(['index', 'show']);
Route::apiResource('banners', \App\Http\Controllers\Api\BannerController::class)->only(['index', 'show']);
Route::apiResource('news-announcements', \App\Http\Controllers\Api\NewsAnnouncementController::class)->only(['index', 'show']);
Route::apiResource('events', EventController::class)->only(['index', 'show']);
Route::apiResource('promotions', PromotionController::class)->only(['index', 'show']);
Route::get('shipping-rates', [\App\Http\Controllers\Api\ShippingRateController::class, 'index']);

// Bakong polling — public endpoint (called by browser from Filament modal)
// Gone, moved to protected routes for consistency with Flutter app

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/user/profile', [AuthController::class, 'updateProfile']);

    Route::apiResource('cart', \App\Http\Controllers\Api\CartItemController::class);
    Route::apiResource('wishlist', \App\Http\Controllers\Api\WishlistController::class)->only(['index', 'store', 'destroy']);
    Route::apiResource('orders', \App\Http\Controllers\Api\OrderController::class)->only(['index', 'show', 'store']);
    Route::post('orders/{order}/send-telegram', [\App\Http\Controllers\Api\OrderController::class, 'sendTelegramInvoice']);
    Route::apiResource('invoices', \App\Http\Controllers\Api\InvoiceController::class)->only(['index', 'show']);
    Route::apiResource('notifications', \App\Http\Controllers\Api\NotificationController::class)->only(['index', 'show', 'destroy']);
    Route::patch('notifications/{notification}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::post('notifications/read-all', [\App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    Route::delete('notifications/delete-all', [\App\Http\Controllers\Api\NotificationController::class, 'destroyAll']);

    Route::post('/notifications/send', [\App\Http\Controllers\Api\FcmNotificationController::class, 'send']);
    Route::post('/devices', [\App\Http\Controllers\Api\UserDeviceController::class, 'store']);
    Route::delete('/devices', [\App\Http\Controllers\Api\UserDeviceController::class, 'destroy']);

    // User Addresses API
    Route::apiResource('user/addresses', \App\Http\Controllers\Api\UserAddressController::class);
    Route::patch('user/addresses/{address}/set-default', [\App\Http\Controllers\Api\UserAddressController::class, 'setDefault']);

    // Payments API
    Route::get('payments', [PaymentController::class, 'index']);
    Route::post('payments', [PaymentController::class, 'store']);
    Route::get('payments/{payment}', [PaymentController::class, 'show']);
    Route::put('payments/{payment}', [PaymentController::class, 'update']);
    Route::get('payments/{payment}/check-khqr', [PaymentController::class, 'checkKhqr']);

    // Reviews API (protected)
    Route::post('reviews', [ReviewController::class, 'store']);
    Route::put('reviews/{review}', [ReviewController::class, 'update']);
    Route::delete('reviews/{review}', [ReviewController::class, 'destroy']);
});
