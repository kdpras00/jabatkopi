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
            if ($order->table_id) {
                Table::find($order->table_id)->update(['status' => 'occupied']);
            }
        } elseif (in_array($transactionStatus, ['deny', 'expire', 'cancel'])) {
            $newStatus = 'cancelled';
            if ($oldStatus !== 'cancelled') {
                $items = DB::table('order_items')->where('order_id', $order->id)->get();
                foreach ($items as $item) {
                    $menu = Menu::find($item->menu_id);
                    if ($menu) {
                        $menu->increment('stock', $item->qty);
                    }
                }
            }
            if ($order->table_id) {
                Table::find($order->table_id)->update(['status' => 'available']);
            }
        }

        if ($newStatus !== $oldStatus) {
            $order->update([
                'status' => $newStatus,
                'payment_method' => strtoupper(str_replace('_', ' ', $paymentType ?? $order->payment_method)),
            ]);

            event(new \App\Events\OrderCreated());
        }

        return response()->json(['message' => 'Notification processed successfully']);
    }
}
