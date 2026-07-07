<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class OrderController extends Controller
{
    public function create(Request $request)
    {
        $request->validate([
            'table_id' => 'required|integer',
            'payment_method' => 'required|string',
            'items' => 'required|array|min:1',
            'items.*.menu_id' => 'required|integer',
            'items.*.qty' => 'required|integer|min:1',
        ]);

        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        try {
            $tableId = $request->table_id;
            $paymentMethod = $request->payment_method;
            $items = $request->items;

            $totalAmount = 0;
            $processedItems = [];

            // Cek stok dan hitung subtotal & total
            foreach ($items as $item) {
                $menu = DB::table('menus')->where('id', $item['menu_id'])->first();
                if (!$menu || $menu->stock < $item['qty']) {
                    throw new \Exception('Stok tidak cukup atau menu tidak ditemukan: ' . ($menu->name ?? 'Unknown'));
                }
                
                $subtotal = $menu->price * $item['qty'];
                $totalAmount += $subtotal;
                
                $processedItems[] = [
                    'menu_id' => $item['menu_id'],
                    'qty' => $item['qty'],
                    'subtotal' => $subtotal,
                ];
            }

            // Potong stok
            foreach ($processedItems as $item) {
                DB::table('menus')->where('id', $item['menu_id'])->decrement('stock', $item['qty']);
            }

            $orderId = DB::table('orders')->insertGetId([
                'customer_id' => $customerId,
                'table_id' => $tableId == 0 ? null : $tableId,
                'is_walk_in' => true,
                'reservation_id' => null,
                'total_amount' => $totalAmount,
                'status' => 'pending',
                'payment_method' => $paymentMethod,
                'staff_name' => 'SISTEM',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($processedItems as $item) {
                DB::table('order_items')->insert([
                    'order_id' => $orderId,
                    'menu_id' => $item['menu_id'],
                    'qty' => $item['qty'],
                    'subtotal' => $item['subtotal'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $result = $orderId;

            $paymentDetails = [];
            $snapToken = '';
            $snapRedirectUrl = '';
            
            if ($request->payment_method !== 'cash') {
                $authString = base64_encode(env('MIDTRANS_SERVER_KEY') . ':');
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

                $response = Http::withHeaders([
                    'Authorization' => 'Basic ' . $authString,
                    'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                ])->post('https://api.sandbox.midtrans.com/v2/charge', $payload);

                if ($response->successful()) {
                    $resData = $response->json();
                    
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

        foreach ($orders as $order) {
            $items = DB::table('order_items')
                ->select('order_items.*', 'menus.name as menu_name', 'menus.image_url')
                ->leftJoin('menus', 'order_items.menu_id', '=', 'menus.id')
                ->where('order_items.order_id', $order->id)
                ->get();
            
            // ponytail: dynamically replace absolute URLs to use our custom CORS image proxy
            foreach ($items as $item) {
                if ($item->image_url && str_contains($item->image_url, '/storage/menus/')) {
                    $filename = basename(parse_url($item->image_url, PHP_URL_PATH));
                    $item->image_url = url('/api/images/menus/' . $filename);
                }
            }
            $order->items = $items;
        }

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $orders]);
    }

    public function active(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);
        $orders = DB::table('orders')->where('customer_id', $customerId)->whereIn('status', ['pending', 'processing', 'ready'])->get();
        return response()->json(['status' => 200, 'data' => $orders]);
    }

    public function byTable($tableId)
    {
        $orders = DB::table('orders')->where('table_id', $tableId)->whereIn('status', ['pending', 'processing'])->get();
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
                $authString = base64_encode(env('MIDTRANS_SERVER_KEY') . ':');
                $response = Http::withHeaders([
                    'Authorization' => 'Basic ' . $authString,
                    'Accept' => 'application/json',
                ])->get('https://api.sandbox.midtrans.com/v2/JK-ORDER-' . $id . '/status');

                if ($response->successful()) {
                    $resData = $response->json();
                    $transactionStatus = $resData['transaction_status'] ?? '';
                    $paymentType = $resData['payment_type'] ?? '';

                    if ($paymentType === 'bank_transfer' && isset($resData['va_numbers'][0]['bank'])) {
                        $paymentType = 'bank_transfer_' . $resData['va_numbers'][0]['bank'];
                    }

                    if ($transactionStatus === 'settlement' || $transactionStatus === 'capture') {
                        DB::table('orders')->where('id', $id)->update([
                            'status' => 'processing',
                            'payment_method' => strtoupper(str_replace('_', ' ', $paymentType)),
                            'updated_at' => now(),
                        ]);
                        
                        if ($order->table_id) {
                            DB::table('tables')->where('id', $order->table_id)->update(['status' => 'occupied']);
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

        return response()->json(['status' => 200, 'data' => $order]);
    }

    public function updateStatus(Request $request, $id)
    {
        DB::table('orders')->where('id', $id)->update(['status' => $request->status, 'updated_at' => now()]);

        if ($request->status === 'ready') {
            try {
                $order = DB::table('orders')->where('id', $id)->first();
                if ($order && $order->customer_id) {
                    $user = DB::table('users')->where('id', $order->customer_id)->first();
                    if ($user && !empty($user->fcm_token)) {
                        $messaging = app('firebase.messaging');
                        $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('token', $user->fcm_token)
                            ->withNotification(\Kreait\Firebase\Messaging\Notification::create(
                                'Pesanan Siap Diambil!',
                                'Pesanan kopi Anda sudah jadi dan siap dinikmati di meja pengambilan.'
                            ))
                            ->withData(['order_id' => $id, 'status' => 'ready']);
                        
                        $messaging->send($message);
                    }
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('FCM Send Error: ' . $e->getMessage());
            }
        }

        return response()->json(['status' => 200, 'message' => 'Status updated']);
    }

    public function cancel($id)
    {
        DB::table('orders')->where('id', $id)->update(['status' => 'cancelled', 'updated_at' => now()]);
        return response()->json(['status' => 200, 'message' => 'Order cancelled']);
    }
}
