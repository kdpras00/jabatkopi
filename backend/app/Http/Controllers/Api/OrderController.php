<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Table;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class OrderController extends Controller
{
    public function create(Request $request)
    {
        $request->validate([
            'table_id'      => 'required_if:order_type,dine_in|nullable|integer',
            'payment_method'=> 'required|string',
            'items'         => 'required|array|min:1',
            'items.*.menu_id' => 'required|integer',
            'items.*.qty'   => 'required|integer|min:1',
            'order_type'    => 'nullable|string|in:dine_in,pickup,takeaway',
            'pickup_time'   => 'required_if:order_type,pickup|nullable|string|max:10',
        ]);

        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        try {
            $tableId = $request->table_id;
            $paymentMethod = $request->payment_method;
            $items = $request->items;
            $orderType = $request->order_type ?? 'dine_in';
            $pickupTime = $request->pickup_time;

            $totalAmount = 0;
            $processedItems = [];

            // ponytail: Bulk fetch all requested menus to avoid N+1 queries in loop
            $menuIds = collect($items)->pluck('menu_id')->unique()->toArray();
            $menus = DB::table('menus')->whereIn('id', $menuIds)->get()->keyBy('id');

            foreach ($items as $item) {
                $menu = $menus->get($item['menu_id']);
                if (!$menu || $menu->deleted_at !== null) {
                    throw new \Exception('Menu tidak ditemukan atau sudah dihapus: ' . ($menu->name ?? 'Unknown'));
                }
                if (!$menu->is_available) {
                    throw new \Exception('Menu tidak tersedia saat ini: ' . $menu->name);
                }
                if ($menu->stock < $item['qty']) {
                    throw new \Exception('Stok tidak cukup untuk menu: ' . $menu->name);
                }
                
                $subtotal = $menu->price * $item['qty'];
                $totalAmount += $subtotal;
                
                $processedItems[] = [
                    'menu_id' => $item['menu_id'],
                    'qty'     => $item['qty'],
                    'subtotal' => $subtotal, // subtotal sebelum pajak (per item)
                ];
            }

            // Tambahkan PPN 10% ke total keseluruhan
            $totalAmount = round($totalAmount * 1.10, 2);

            // Cek Tabrakan Meja (Collision Prevention)
            if (!empty($tableId)) {
                $table = DB::table('tables')->where('id', $tableId)->first();
                if (!$table) {
                    throw new \Exception('Meja tidak ditemukan.');
                }
                if ($table->status === 'occupied') {
                    // Hanya izinkan jika user ini yang sedang menempati meja (Pesanan Tambahan)
                    $hasActiveOrder = DB::table('orders')
                        ->where('table_id', $tableId)
                        ->where('customer_id', $customerId)
                        ->whereIn('status', ['pending', 'processing', 'preparing', 'ready'])
                        ->exists();
                        
                    if (!$hasActiveOrder) {
                        throw new \Exception('Meja ini sudah terisi oleh pelanggan lain.');
                    }
                }
            }

            // Wrap all database operations in a transaction
            $orderId = DB::transaction(function () use ($customerId, $tableId, $paymentMethod, $processedItems, $totalAmount, $orderType, $pickupTime) {
                // Potong stok
                foreach ($processedItems as $item) {
                    DB::table('menus')->where('id', $item['menu_id'])->decrement('stock', $item['qty']);
                }

                $id = DB::table('orders')->insertGetId([
                    'customer_id'    => $customerId,
                    'table_id'       => ($tableId == 0 || $tableId === null) ? null : $tableId,
                    'is_walk_in'     => true,
                    'reservation_id' => null,
                    'total_amount'   => $totalAmount,
                    'status'         => 'pending',
                    'payment_method' => $paymentMethod,
                    'staff_name'     => 'SISTEM',
                    'order_type'     => $orderType,
                    'pickup_time'    => ($orderType === 'pickup') ? $pickupTime : null,
                    'created_at'     => now(),
                    'updated_at'     => now(),
                ]);

                foreach ($processedItems as $item) {
                    DB::table('order_items')->insert([
                        'order_id'   => $id,
                        'menu_id'    => $item['menu_id'],
                        'qty'        => $item['qty'],
                        'subtotal'   => $item['subtotal'],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                return $id;
            });

            $result = $orderId;

            $paymentDetails = [];
            $snapToken = '';
            $snapRedirectUrl = '';
            
            if ($request->payment_method !== 'cash') {
                $authString = base64_encode(config('services.midtrans.server_key') . ':');
                $orderIdString = 'JK-ORDER-' . $result;
                $grossAmount = (int)$totalAmount;

                $payload = [
                    'transaction_details' => [
                        'order_id' => $orderIdString,
                        'gross_amount' => $grossAmount
                    ],
                    'customer_details' => [
                        'first_name' => 'Customer',
                        'last_name' => (string) $customerId,
                        'email' => 'customer' . $customerId . '@jabatkopi.my.id',
                        'phone' => '080000000000'
                    ]
                ];

                switch ($request->payment_method) {
                    case 'bank_transfer_bca':
                        $payload['payment_type'] = 'bank_transfer';
                        $payload['bank_transfer'] = ['bank' => 'bca'];
                        break;
                    case 'bank_transfer_bni':
                        $payload['payment_type'] = 'bank_transfer';
                        $payload['bank_transfer'] = ['bank' => 'bni'];
                        break;
                    case 'bank_transfer_bri':
                        $payload['payment_type'] = 'bank_transfer';
                        $payload['bank_transfer'] = ['bank' => 'bri'];
                        break;
                    case 'bank_transfer_permata':
                        $payload['payment_type'] = 'bank_transfer';
                        $payload['bank_transfer'] = ['bank' => 'permata'];
                        break;
                    case 'bank_transfer_mandiri':
                        $payload['payment_type'] = 'echannel';
                        $payload['echannel'] = ['bill_info1' => 'Payment', 'bill_info2' => 'Online'];
                        break;
                    case 'cstore_alfamart':
                        $payload['payment_type'] = 'cstore';
                        $payload['cstore'] = ['store' => 'alfamart', 'message' => 'Jabat Kopi'];
                        break;
                    case 'cstore_indomaret':
                        $payload['payment_type'] = 'cstore';
                        $payload['cstore'] = ['store' => 'indomaret', 'message' => 'Jabat Kopi'];
                        break;
                    case 'gopay':
                        $payload['payment_type'] = 'gopay';
                        $payload['gopay'] = ['enable_callback' => true, 'callback_url' => 'https://jabatkopi.my.id'];
                        break;
                    case 'shopeepay':
                        $payload['payment_type'] = 'shopeepay';
                        $payload['shopeepay'] = ['callback_url' => 'https://jabatkopi.my.id'];
                        break;
                    case 'qris':
                        $payload['payment_type'] = 'qris';
                        break;
                    default:
                        $payload['payment_type'] = 'bank_transfer';
                        $payload['bank_transfer'] = ['bank' => 'bca'];
                        break;
                }

                $serverKey = config('services.midtrans.server_key');
                $isProduction = config('services.midtrans.is_production');
                $midtransApiUrl = $isProduction ? 'https://api.midtrans.com/v2/charge' : 'https://api.sandbox.midtrans.com/v2/charge';

                $response = Http::withHeaders([
                    'Authorization' => 'Basic ' . $authString,
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                ])->post($midtransApiUrl, $payload);

                if ($response->successful()) {
                    $resData = $response->json();
                    
                    $transactionStatus = $resData['transaction_status'] ?? 'pending';
                    if (in_array($transactionStatus, ['deny', 'cancel', 'expire'])) {
                        throw new \Exception('Payment was denied by Midtrans: ' . ($resData['status_message'] ?? ''));
                    }

                    if (isset($resData['va_numbers'][0]['va_number'])) {
                        $paymentDetails['va_number'] = $resData['va_numbers'][0]['va_number'];
                        $paymentDetails['bank'] = $resData['va_numbers'][0]['bank'];
                    } else if (isset($resData['permata_va_number'])) {
                        $paymentDetails['va_number'] = $resData['permata_va_number'];
                        $paymentDetails['bank'] = 'permata';
                    }

                    if (isset($resData['biller_code']) && isset($resData['bill_key'])) {
                        $paymentDetails['biller_code'] = $resData['biller_code'];
                        $paymentDetails['bill_key'] = $resData['bill_key'];
                    }

                    if (isset($resData['payment_code'])) {
                        $paymentDetails['payment_code'] = $resData['payment_code'];
                    }

                    if (isset($resData['actions']) && is_array($resData['actions'])) {
                        foreach ($resData['actions'] as $action) {
                            if ($action['name'] === 'generate-qr-code') {
                                $paymentDetails['qr_url'] = $action['url'];
                            }
                            if ($action['name'] === 'deeplink-redirect') {
                                $paymentDetails['deeplink_url'] = $action['url'];
                            }
                        }
                    }
                } else {
                    \Illuminate\Support\Facades\Log::error('Midtrans Charge Failed: ' . $response->body());
                    throw new \Exception('Midtrans error: ' . $response->json('status_message', 'Payment gateway error'));
                }
            }

            if (!empty($paymentDetails)) {
                DB::table('orders')->where('id', $result)->update([
                    'payment_details' => json_encode($paymentDetails),
                ]);
            }

            // 5. Sinkronisasi status meja otomatis (misal jadi occupied)
            if (!empty($tableId)) {
                \App\Models\Table::syncStatus($tableId);
            }

            event(new \App\Events\OrderCreated());

            return response()->json([
                'status' => 201,
                'message' => 'Order created successfully',
                'data' => [
                    'order' => ['id' => $result, 'status' => 'pending'],
                    'payment_details' => $paymentDetails,
                    'snap_token' => $snapToken,
                    'snap_redirect_url' => $snapRedirectUrl,
                ]
            ]);

        } catch (\Throwable $e) {
            if (isset($result)) {
                $items = DB::table('order_items')->where('order_id', $result)->get();
                foreach ($items as $item) {
                    DB::table('menus')->where('id', $item->menu_id)->increment('stock', $item->qty);
                }
                DB::table('order_items')->where('order_id', $result)->delete();
                DB::table('orders')->where('id', $result)->delete();
            }
            \Illuminate\Support\Facades\Log::error('Order creation failed: ' . $e->getMessage() . ' on line ' . $e->getLine());
            return response()->json(['message' => $e->getMessage()], 400);
        }

    }
    public function history(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        $orders = DB::table('orders')
            ->select('orders.*', 'tables.id as table_number')
            ->leftJoin('tables', 'orders.table_id', '=', 'tables.id')
            ->where('orders.customer_id', $customerId)
            ->orderBy('orders.created_at', 'desc')
            ->get();

        if ($orders->isNotEmpty()) {
            // ponytail: 1 bulk query instead of N per-order queries
            $orderIds = $orders->pluck('id');
            $allItems = DB::table('order_items')
                ->select('order_items.*', 'menus.name as menu_name', 'menus.image_url')
                ->leftJoin('menus', 'order_items.menu_id', '=', 'menus.id')
                ->whereIn('order_items.order_id', $orderIds)
                ->get()
                ->groupBy('order_id');

            foreach ($orders as $order) {
                $items = $allItems->get($order->id, collect());
                foreach ($items as $item) {
                    if ($item->image_url && str_contains($item->image_url, '/storage/menus/')) {
                        $filename = basename(parse_url($item->image_url, PHP_URL_PATH));
                        $item->image_url = url('/api/images/menus/' . $filename);
                    }
                }
                $order->items = $items->values();
                $order->payment_details = $order->payment_details ? json_decode($order->payment_details, true) : null;
            }
        }

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $orders]);
    }

    public function active(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);
        $orders = DB::table('orders')->where('customer_id', $customerId)->whereIn('status', ['pending', 'processing', 'preparing', 'ready'])->get();
        return response()->json(['status' => 200, 'data' => $orders]);
    }

    public function byTable($tableId)
    {
        $orders = DB::table('orders')->where('table_id', $tableId)->whereIn('status', ['pending', 'processing', 'preparing', 'ready'])->get();
        return response()->json(['status' => 200, 'data' => $orders]);
    }

    public function details($id)
    {
        $order = DB::table('orders')
            ->select('orders.*', 'users.name as customer_name', 'users.email as customer_email')
            ->leftJoin('users', 'orders.customer_id', '=', 'users.id')
            ->where('orders.id', $id)
            ->first();

        if(!$order) return response()->json(['message' => 'Not found'], 404);

        if ($order->status === 'pending' || $order->payment_method === 'BANK TRANSFER' || $order->payment_method === 'bank_transfer') {
            try {
                $authString = base64_encode(config('services.midtrans.server_key') . ':');
                $isProduction = config('services.midtrans.is_production', false);
                $midtransApiUrl = $isProduction ? 'https://api.midtrans.com/v2/' : 'https://api.sandbox.midtrans.com/v2/';
                $response = Http::withHeaders([
                    'Authorization' => 'Basic ' . $authString,
                    'Accept' => 'application/json',
                ])->get($midtransApiUrl . 'JK-ORDER-' . $id . '/status');

                if ($response->successful()) {
                    $resData = $response->json();
                    $transactionStatus = $resData['transaction_status'] ?? '';
                    $paymentType = $resData['payment_type'] ?? '';

                    if ($paymentType === 'bank_transfer' && isset($resData['va_numbers'][0]['bank'])) {
                        $paymentType = 'bank_transfer_' . $resData['va_numbers'][0]['bank'];
                    }

                    $paymentDetails = json_decode($order->payment_details, true) ?? [];
                    $detailsUpdated = false;

                    if (empty($paymentDetails)) {
                        if (isset($resData['va_numbers'][0]['va_number'])) {
                            $paymentDetails['va_number'] = $resData['va_numbers'][0]['va_number'];
                            $paymentDetails['bank'] = $resData['va_numbers'][0]['bank'];
                            $detailsUpdated = true;
                        } else if (isset($resData['permata_va_number'])) {
                            $paymentDetails['va_number'] = $resData['permata_va_number'];
                            $paymentDetails['bank'] = 'permata';
                            $detailsUpdated = true;
                        }

                        if (isset($resData['biller_code']) && isset($resData['bill_key'])) {
                            $paymentDetails['biller_code'] = $resData['biller_code'];
                            $paymentDetails['bill_key'] = $resData['bill_key'];
                            $detailsUpdated = true;
                        }

                        if (isset($resData['payment_code'])) {
                            $paymentDetails['payment_code'] = $resData['payment_code'];
                            $detailsUpdated = true;
                        }

                        if (isset($resData['actions']) && is_array($resData['actions'])) {
                            foreach ($resData['actions'] as $action) {
                                if ($action['name'] === 'generate-qr-code') {
                                    $paymentDetails['qr_url'] = $action['url'];
                                    $detailsUpdated = true;
                                }
                                if ($action['name'] === 'deeplink-redirect') {
                                    $paymentDetails['deeplink_url'] = $action['url'];
                                    $detailsUpdated = true;
                                }
                            }
                        }

                        if ($detailsUpdated) {
                            DB::table('orders')->where('id', $id)->update([
                                'payment_details' => json_encode($paymentDetails),
                                'updated_at' => now(),
                            ]);
                            $order->payment_details = json_encode($paymentDetails);
                        }
                    }

                    if ($transactionStatus === 'settlement' || $transactionStatus === 'capture') {
                        DB::table('orders')->where('id', $id)->update([
                            'status'         => 'processing',
                            'payment_method' => strtoupper(str_replace('_', ' ', $paymentType)),
                            'updated_at'     => now(),
                        ]);

                        // Sinkronisasi status meja secara otomatis
                        if ($order->table_id) {
                            \App\Models\Table::syncStatus($order->table_id);
                        }

                        event(new \App\Events\OrderCreated());

                        // Refresh order record
                        $order = DB::table('orders')
                            ->select('orders.*', 'users.name as customer_name', 'users.email as customer_email')
                            ->leftJoin('users', 'orders.customer_id', '=', 'users.id')
                            ->where('orders.id', $id)
                            ->first();
                    }
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('Failed to sync payment from Midtrans: ' . $e->getMessage());
            }
        }

        $order->items = DB::table('order_items')
            ->select('order_items.*', 'menus.name as menu_name', 'menus.price as price')
            ->leftJoin('menus', 'order_items.menu_id', '=', 'menus.id')
            ->where('order_items.order_id', $id)
            ->get();
            
        $order->payment_details = $order->payment_details ? json_decode($order->payment_details, true) : null;

        return response()->json(['status' => 200, 'data' => $order]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string|in:pending,processing,preparing,ready,completed,cancelled']);
        
        $status = $request->status;
        $order = DB::table('orders')->where('id', $id)->first();
        if (!$order) return response()->json(['message' => 'Order not found'], 404);

        // Filter 1: Cegah Spam dari klik berulang (Status tidak berubah)
        if ($order->status === $status) {
            return response()->json(['status' => 200, 'message' => 'Status tidak berubah (skip notifikasi)']);
        }

        DB::table('orders')->where('id', $id)->update(['status' => $status, 'updated_at' => now()]);

        // Jika order selesai atau dibatalkan, sinkronisasi status meja
        if (in_array($status, ['completed', 'cancelled']) && $order->table_id) {
            \App\Models\Table::syncStatus($order->table_id);
        }

        // Send FCM Notification
        $user = DB::table('users')->where('id', $order->customer_id)->first();
        if ($user && $user->fcm_token) {
            $title = '';
            $body = '';

            // Filter 2: Sesuaikan tingkat urgensi berdasarkan Tipe Pesanan
            // Dine In tidak perlu terlalu banyak notif karena pelanggan sudah duduk di tempat.
            // Pickup / Takeaway sangat butuh notifikasi "Ready".
            
            if ($status === 'processing') {
                if ($order->order_type !== 'dine_in') { // Hanya untuk Pickup/Takeaway
                    $title = 'Pesanan Diproses \u{2615}';
                    $body = "Pesananmu (#{$order->id}) sedang diracik oleh barista kami!";
                }
            } elseif ($status === 'ready') {
                $title = 'Pesanan Siap! \u{1F6CD}';
                if ($order->order_type === 'dine_in') {
                    $body = "Yay! Pesananmu (#{$order->id}) sedang diantar ke mejamu.";
                } else {
                    $body = "Yay! Pesananmu (#{$order->id}) sudah siap diambil di kasir.";
                }
            } elseif ($status === 'completed' && $order->order_type !== 'dine_in') {
                // Selesai untuk Dine In biasanya kasir yang klik pas pelanggan bayar/pergi, tidak perlu dispam
                $title = 'Pesanan Selesai \u{2705}';
                $body = "Terima kasih sudah menikmati sajian Jabat Kopi!";
            } elseif ($status === 'cancelled') {
                $title = 'Pesanan Dibatalkan \u{274C}';
                $body = "Pesananmu (#{$order->id}) telah dibatalkan oleh pihak kafe.";
            }

            if ($title && $body) {
                (new \App\Services\FcmService())->sendNotification(
                    $user->fcm_token,
                    $title,
                    $body,
                    ['type' => 'order_status_update', 'order_id' => (string) $order->id, 'status' => $status]
                );
            }
        }

        event(new \App\Events\OrderCreated());
        return response()->json(['status' => 200, 'message' => 'Status updated']);
    }

    public function cancel($id)
    {
        $order = Order::find($id);
        if (!$order) return response()->json(['message' => 'Order tidak ditemukan'], 404);

        // Hanya izinkan pembatalan milik pelanggan yang sedang login
        if (auth()->id() && $order->customer_id !== auth()->id()) {
            return response()->json(['message' => 'Tidak diizinkan membatalkan pesanan ini'], 403);
        }

        if ($order->status === 'cancelled') {
            return response()->json(['message' => 'Pesanan sudah dibatalkan sebelumnya'], 400);
        }

        // 1. Kembalikan stok menu
        DB::table('menus')
            ->joinSub(
                DB::table('order_items')->where('order_id', $order->id)->select('menu_id', 'qty'),
                'oi', 'oi.menu_id', '=', 'menus.id'
            )
            ->update(['menus.stock' => DB::raw('menus.stock + oi.qty')]);

        // 2. Update status order
        $order->update(['status' => 'cancelled', 'updated_at' => now()]);

        // 3. Sinkronisasi status meja otomatis
        if ($order->table_id) {
            \App\Models\Table::syncStatus($order->table_id);
        }

        event(new \App\Events\OrderCreated());

        return response()->json(['status' => 200, 'message' => 'Pesanan berhasil dibatalkan']);
    }
}
