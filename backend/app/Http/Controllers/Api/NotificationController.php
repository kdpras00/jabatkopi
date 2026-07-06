<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $customerId = $request->header('X-User-Id');
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        $notifications = DB::table('notifications')
            ->where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $notifications]);
    }
}
