<?php

namespace App\Http\Controllers;

use App\Models\Author;
use App\Models\Book;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Services\BakongService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class PosController extends Controller
{
    public function index(Request $request): Response
    {
        $books = Book::query()
            ->with(['author', 'category', 'promotion', 'primaryImage'])
            ->when($request->search, fn($q) => $q->where('title', 'like', '%' . $request->search . '%'))
            ->when($request->author_id, fn($q) => $q->where('author_id', $request->author_id))
            ->when($request->category_id, fn($q) => $q->where('category_id', $request->category_id))
            ->when($request->discount, function($q) {
                $q->whereHas('promotion', fn($pq) => $pq->where('status', 'active'));
            })
            ->latest()
            ->paginate(12)
            ->withQueryString();

        return Inertia::render('Pos/Index', [
            'books' => $books,
            'authors' => Author::orderBy('name')->get(),
            'categories' => Category::orderBy('name')->get(),
            'cart' => session()->get('pos_cart', []),
            'filters' => $request->only(['search', 'author_id', 'category_id', 'discount']),
        ]);
    }

    public function addToCart(Request $request)
    {
        $bookId = $request->book_id;
        $book = Book::with(['promotion', 'author', 'primaryImage'])->find($bookId);
        
        if (!$book) {
            return back()->with('error', 'Book not found');
        }

        $cart = session()->get('pos_cart', []);
        $price = $book->discounted_price ?? $book->price;

        if (isset($cart[$bookId])) {
            $cart[$bookId]['quantity']++;
        } else {
            $cart[$bookId] = [
                'id' => $book->id,
                'title' => $book->title,
                'author' => $book->author?->name,
                'price' => (float)$price,
                'quantity' => 1,
                'image' => $book->primaryImage?->getOptimizedImageUrl($book->primaryImage->image_url, 100, 100),
                'direct_image' => rtrim(config('filesystems.disks.supabase.url'), '/') . '/' . ltrim($book->primaryImage?->image_url, '/'),
            ];
        }

        session()->put('pos_cart', $cart);
        return back()->with('success', 'Added to cart');
    }

    public function updateQuantity(Request $request)
    {
        $cart = session()->get('pos_cart', []);
        $id = $request->id;
        $quantity = $request->quantity;

        if (isset($cart[$id])) {
            if ($quantity <= 0) {
                unset($cart[$id]);
            } else {
                $cart[$id]['quantity'] = $quantity;
            }
            session()->put('pos_cart', $cart);
        }

        return back();
    }

    public function removeFromCart($id)
    {
        $cart = session()->get('pos_cart', []);
        if (isset($cart[$id])) {
            unset($cart[$id]);
            session()->put('pos_cart', $cart);
        }
        return back()->with('success', 'Removed from cart');
    }

    public function checkout(Request $request)
    {
        $cart = session()->get('pos_cart', []);
        if (empty($cart)) {
            return back()->with('error', 'Cart is empty');
        }

        DB::beginTransaction();
        try {
            $subtotal = collect($cart)->sum(fn($item) => $item['price'] * $item['quantity']);

            $order = Order::create([
                'user_id' => auth()->id(),
                'subtotal' => $subtotal,
                'shipping_fee' => 0,
                'total_price' => $subtotal,
                'status' => 'pending',
                'payment_method' => 'bakong',
            ]);

            foreach ($cart as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'book_id' => $item['id'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['price'],
                    'total_price' => $item['price'] * $item['quantity'],
                ]);
            }

            $payment = Payment::create([
                'order_id' => $order->id,
                'method' => 'bakong',
                'amount' => $subtotal,
                'status' => 'pending',
            ]);

            $bakongService = app(BakongService::class);
            $result = $bakongService->generateQR($payment);

            if ($result) {
                $payment->update(['txn_id' => $result['md5']]);
                DB::commit();

                return response()->json([
                    'qrCodeUrl' => $bakongService->getQrImageUrl($result['qr']),
                    'order' => $order,
                    'payment' => $payment,
                    'md5' => $result['md5'],
                ]);
            } else {
                throw new \Exception('Failed to generate QR Code');
            }
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }
}
