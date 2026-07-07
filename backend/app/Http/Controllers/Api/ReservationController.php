<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReservationController extends Controller
{
    public function index(Request $request)
    {
        $customerId = auth()->id();
        $reservations = DB::table('reservations')
            ->select('reservations.*', 'tables.id as table_number', 'tables.capacity as table_capacity', 'users.name as user_name', 'users.email as user_email')
            ->leftJoin('tables', 'reservations.table_id', '=', 'tables.id')
            ->leftJoin('users', 'reservations.customer_id', '=', 'users.id')
            ->where('reservations.customer_id', $customerId)
            ->orderBy('reservations.created_at', 'desc')
            ->get();
            
        $data = $reservations->map(function ($r) {
            $arr = (array)$r;
            $arr['tables'] = ['number' => $r->table_number, 'capacity' => $r->table_capacity];
            $arr['users'] = ['name' => $r->user_name, 'email' => $r->user_email];
            $arr['qr_code'] = $r->barcode;
            return $arr;
        });

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $data]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'table_id' => 'required|integer',
            'reservation_date' => 'required|date',
            'guest_count' => 'required|integer|min:1',
        ]);

        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Sesi tidak valid'], 401);

        $tableId = $request->table_id;
        $date = $request->reservation_date;
        $guestCount = $request->guest_count;

        $end = date('Y-m-d H:i:s', strtotime($date . ' +2 hours'));
        $start = date('Y-m-d H:i:s', strtotime($date . ' -2 hours'));

        if ($tableId == 0) {
            // Auto-allocate table
            // Find all tables that have capacity >= guest_count, are status 'available', and do not conflict
            $availableTable = DB::table('tables')
                ->whereNull('deleted_at')
                ->where('capacity', '>=', $guestCount)
                ->where('status', 'available')
                ->whereNotExists(function ($query) use ($start, $end) {
                    $query->select(DB::raw(1))
                        ->from('reservations')
                        ->whereRaw('reservations.table_id = tables.id')
                        ->where('reservation_date', '>=', $start)
                        ->where('reservation_date', '<=', $end)
                        ->whereIn('status', ['booked', 'confirmed', 'valid', 'checked_in']);
                })
                ->orderBy('capacity', 'asc') // prefer smallest table that fits
                ->first();

            if (!$availableTable) {
                return response()->json(['message' => 'Tidak ada meja yang tersedia untuk jumlah tamu tersebut pada rentang waktu ini.'], 400);
            }
            $tableId = $availableTable->id;
        } else {
            $conflict = DB::table('reservations')
                ->where('table_id', $tableId)
                ->where('reservation_date', '>=', $start)
                ->where('reservation_date', '<=', $end)
                ->whereIn('status', ['booked', 'confirmed', 'valid', 'checked_in'])
                ->first();

            if ($conflict) {
                return response()->json(['message' => 'Meja sudah dipesan pada rentang waktu tersebut.'], 400);
            }
        }

        $id = DB::table('reservations')->insertGetId([
            'customer_id' => $customerId,
            'table_id' => $tableId,
            'reservation_date' => $date,
            'pax' => $request->guest_count,
            'notes' => $request->special_request ?? '',
            'status' => 'booked',
            'barcode' => 'QR-' . time() . '-' . rand(1000,9999),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $reservation = DB::table('reservations')->where('id', $id)->first();
        return response()->json(['status' => 201, 'message' => 'Reservation created', 'data' => $reservation]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:booked,confirmed,valid,checked_in,cancelled,completed',
        ]);

        $status = $request->status;
        $staff = $request->header('X-Username', 'BARISTA');
        
        DB::table('reservations')->where('id', $id)->update([
            'status' => $status,
            'verified_by' => $staff,
            'verified_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['status' => 200, 'message' => 'Reservation status updated']);
    }

    public function cancel($id)
    {
        DB::table('reservations')->where('id', $id)->update([
            'status' => 'cancelled',
            'updated_at' => now(),
        ]);
        return response()->json(['status' => 200, 'message' => 'Reservation cancelled']);
    }

    public function adminIndex()
    {
        $reservations = DB::table('reservations')
            ->select('reservations.*', 'tables.id as table_number', 'tables.capacity as table_capacity', 'users.name as user_name', 'users.email as user_email')
            ->leftJoin('tables', 'reservations.table_id', '=', 'tables.id')
            ->leftJoin('users', 'reservations.customer_id', '=', 'users.id')
            ->orderBy('reservations.created_at', 'desc')
            ->get();
            
        $data = $reservations->map(function ($r) {
            $arr = (array)$r;
            $arr['tables'] = ['number' => $r->table_number, 'capacity' => $r->table_capacity];
            $arr['users'] = ['name' => $r->user_name, 'email' => $r->user_email];
            $arr['qr_code'] = $r->barcode;
            return $arr;
        });

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $data]);
    }

    public function active(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);
        $reservations = DB::table('reservations')
            ->where('customer_id', $customerId)
            ->whereIn('status', ['booked', 'confirmed', 'valid', 'checked_in'])
            ->get();
        return response()->json(['status' => 200, 'data' => $reservations]);
    }
}
