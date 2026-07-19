<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TableController extends Controller
{
    public function index()
    {
        $tables = DB::table('tables')
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->get();

        // Sertakan jumlah order aktif per meja agar Flutter bisa tampilkan
        // informasi real (ada pesanan aktif atau tidak) tanpa bergantung pada field `status`.
        $activeOrderCounts = DB::table('orders')
            ->whereIn('status', ['pending', 'processing', 'preparing', 'ready'])
            ->whereNotNull('table_id')
            ->groupBy('table_id')
            ->select('table_id', DB::raw('count(*) as active_order_count'))
            ->pluck('active_order_count', 'table_id');

        $tables = $tables->map(function ($table) use ($activeOrderCounts) {
            $table->active_order_count = $activeOrderCounts->get($table->id, 0);
            return $table;
        });

        return response()->json(['status' => 200, 'message' => 'Success', 'data' => $tables]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'number' => 'required|integer|unique:tables,number,NULL,id,deleted_at,NULL',
            'capacity' => 'required|integer|min:1',
        ]);

        $id = DB::table('tables')->insertGetId([
            'number'      => $request->number,
            'qr_code_ref' => 'MEJA-' . str_pad($request->number, 2, '0', STR_PAD_LEFT),
            'capacity'    => $request->capacity,
            'status'      => $request->status ?? 'available',
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
        $table = DB::table('tables')->where('id', $id)->first();
        return response()->json(['status' => 201, 'message' => 'Table created', 'data' => $table]);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'number' => 'required|integer|unique:tables,number,' . $id . ',id,deleted_at,NULL',
            'capacity' => 'required|integer|min:1',
        ]);

        DB::table('tables')->where('id', $id)->update([
            'number' => $request->number,
            'capacity' => $request->capacity,
            'status' => $request->status ?? 'available',
            'updated_at' => now(),
        ]);
        $table = DB::table('tables')->where('id', $id)->first();
        return response()->json(['status' => 200, 'message' => 'Table updated', 'data' => $table]);
    }

    public function destroy($id)
    {
        $table = DB::table('tables')->where('id', $id)->first();
        if ($table && $table->status !== 'available') {
            return response()->json(['message' => 'Meja sedang terpakai, tidak dapat dihapus.'], 400);
        }
        DB::table('tables')->where('id', $id)->update(['deleted_at' => now()]);
        return response()->json(['status' => 200, 'message' => 'Table deleted']);
    }

    public function getWithReservations(Request $request)
    {
        $dateStr = $request->query('date', date('Y-m-d'));
        $start = date('Y-m-d', strtotime($dateStr)) . ' 00:00:00';
        $end = date('Y-m-d', strtotime($dateStr . ' +1 day')) . ' 00:00:00';

        $tables = DB::table('tables')->whereNull('deleted_at')->orderBy('id')->get();
        $reservations = DB::table('reservations')
            ->where('reservation_date', '>=', $start)
            ->where('reservation_date', '<', $end)
            ->whereIn('status', ['booked', 'confirmed', 'valid', 'checked_in'])
            ->get();

        $tableData = [];
        foreach ($tables as $t) {
            $tArray = (array)$t;
            $tArray['reservations'] = $reservations->where('table_id', $t->id)->values()->toArray();
            $tableData[] = $tArray;
        }

        return response()->json(['status' => 200, 'message' => 'Success fetching tables and reservations', 'data' => $tableData]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);
        DB::table('tables')->where('id', $id)->update(['status' => $request->status, 'updated_at' => now()]);
        return response()->json(['status' => 200, 'message' => 'Status updated']);
    }

    public function available(Request $request)
    {
        $tables = DB::table('tables')->whereNull('deleted_at')->where('status', 'available')->get();
        return response()->json(['status' => 200, 'data' => $tables]);
    }
}
