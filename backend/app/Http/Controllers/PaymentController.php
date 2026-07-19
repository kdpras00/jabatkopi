<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Menu;
use App\Models\Table;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function handleNotification(Request $request)
    {
        Log::info('Midtrans Webhook Received', $request->all());

        $orderIdStr = $request->input('order_id');
        $transactionStatus = $request->input('transaction_status');
        $paymentType = $request->input('payment_type');
        $statusCode = $request->input('status_code');
        $grossAmount = $request->input('gross_amount');
        $signatureKey = $request->input('signature_key');

        $serverKey = config('services.midtrans.server_key');
        $expectedSignature = hash('sha512', $orderIdStr . $statusCode . $grossAmount . $serverKey);

        if ($expectedSignature !== $signatureKey) {
            Log::warning('Invalid Midtrans Signature', ['request' => $request->all()]);
            return response()->json(['message' => 'Invalid signature key'], 403);
        }

        if (!$orderIdStr) {
            return response()->json(['message' => 'Invalid payload'], 400);
        }

        $order = Order::find(str_replace('JK-ORDER-', '', $orderIdStr));

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        $oldStatus = $order->status;
        $newStatus = $oldStatus;

        if ($transactionStatus === 'settlement' || $transactionStatus === 'capture') {
            $newStatus = 'processing';
        } elseif (in_array($transactionStatus, ['deny', 'expire', 'cancel'])) {
            $newStatus = 'cancelled';
        }

        if ($newStatus !== $oldStatus) {
            $order->update([
                'status' => $newStatus,
                'payment_method' => $order->payment_method ?: strtoupper(str_replace('_', ' ', $paymentType)),
            ]);

            // Sync after status is updated in DB
            if ($newStatus === 'processing' && $order->table_id) {
                Table::find($order->table_id)->update(['status' => 'occupied']);
            } elseif ($newStatus === 'cancelled') {
                if ($oldStatus !== 'cancelled') {
                    DB::table('menus')
                        ->joinSub(
                            DB::table('order_items')->where('order_id', $order->id)->select('menu_id', 'qty'),
                            'oi', 'oi.menu_id', '=', 'menus.id'
                        )
                        ->update(['menus.stock' => DB::raw('menus.stock + oi.qty')]);
                }
                if ($order->table_id) {
                    Table::syncStatus($order->table_id);
                }
            }

            event(new \App\Events\OrderCreated());
        }

        return response()->json(['message' => 'Notification processed successfully']);
    }
}
