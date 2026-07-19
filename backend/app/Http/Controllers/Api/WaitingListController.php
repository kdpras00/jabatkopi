<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\FcmService;

class WaitingListController extends Controller
{
    // ─── CUSTOMER ENDPOINTS ──────────────────────────────────────────────────

    /**
     * Customer join waiting list.
     * POST /waiting-list
     */
    public function join(Request $request)
    {
        $request->validate([
            'party_size' => 'required|integer|min:1|max:20',
            'notes'      => 'nullable|string|max:255',
            'fcm_token'  => 'nullable|string',
        ]);

        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        // Cek apakah customer sudah ada di antrian aktif
        $existing = DB::table('waiting_list')
            ->where('customer_id', $customerId)
            ->whereIn('status', ['waiting', 'notified'])
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'Anda sudah ada dalam daftar tunggu.',
                'data'    => $existing,
            ], 400);
        }

        // Generate nomor antrean harian (reset tiap hari)
        $today = now()->startOfDay();
        $lastQueue = DB::table('waiting_list')
            ->whereDate('created_at', now()->toDateString())
            ->max('queue_number') ?? 0;
        $queueNumber = $lastQueue + 1;

        // Simpan FCM token ke profil user jika dikirim
        if ($request->fcm_token) {
            DB::table('users')->where('id', $customerId)
                ->update(['fcm_token' => $request->fcm_token]);
        }

        $id = DB::table('waiting_list')->insertGetId([
            'customer_id'  => $customerId,
            'queue_number' => $queueNumber,
            'party_size'   => $request->party_size,
            'status'       => 'waiting',
            'fcm_token'    => $request->fcm_token,
            'notes'        => $request->notes,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        $entry = DB::table('waiting_list')
            ->where('id', $id)
            ->first();

        // Hitung posisi antrean (berapa orang di depan)
        $position = DB::table('waiting_list')
            ->where('status', 'waiting')
            ->where('id', '<', $id)
            ->count();

        return response()->json([
            'status'  => 201,
            'message' => 'Berhasil masuk daftar tunggu!',
            'data'    => array_merge((array) $entry, ['position' => $position + 1]),
        ]);
    }

    /**
     * Customer lihat status antrian sendiri.
     * GET /waiting-list/my
     */
    public function myStatus(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);

        $entry = DB::table('waiting_list')
            ->where('customer_id', $customerId)
            ->whereIn('status', ['waiting', 'notified'])
            ->orderBy('id', 'desc')
            ->first();

        if (!$entry) {
            return response()->json(['status' => 200, 'data' => null]);
        }

        // Posisi dalam antrian
        $position = DB::table('waiting_list')
            ->where('status', 'waiting')
            ->where('id', '<', $entry->id)
            ->count();

        // Total antrian aktif
        $totalWaiting = DB::table('waiting_list')
            ->where('status', 'waiting')
            ->count();

        return response()->json([
            'status' => 200,
            'data'   => array_merge((array) $entry, [
                'position'      => $position + 1,
                'total_waiting' => $totalWaiting,
                'estimated_wait_minutes' => $position * 15, // estimasi 15 menit per antrean
            ]),
        ]);
    }

    /**
     * Customer batalkan antrian sendiri.
     * PUT /waiting-list/{id}/cancel
     */
    public function cancelMy($id)
    {
        $customerId = auth()->id();
        $entry = DB::table('waiting_list')
            ->where('id', $id)
            ->where('customer_id', $customerId)
            ->first();

        if (!$entry) {
            return response()->json(['message' => 'Antrian tidak ditemukan'], 404);
        }

        if (!in_array($entry->status, ['waiting', 'notified'])) {
            return response()->json(['message' => 'Antrian tidak dapat dibatalkan'], 400);
        }

        DB::table('waiting_list')->where('id', $id)->update([
            'status'     => 'cancelled',
            'updated_at' => now(),
        ]);

        if ($entry->table_id) {
            \App\Models\Table::syncStatus($entry->table_id);
        }

        return response()->json(['status' => 200, 'message' => 'Antrian berhasil dibatalkan']);
    }

    // ─── ADMIN ENDPOINTS ─────────────────────────────────────────────────────

    /**
     * Admin lihat semua antrian aktif.
     * GET /admin/waiting-list
     */
    public function adminIndex()
    {
        $entries = DB::table('waiting_list')
            ->select(
                'waiting_list.*',
                'users.name as customer_name',
                'users.email as customer_email',
                'users.image_url as customer_avatar',
            )
            ->leftJoin('users', 'waiting_list.customer_id', '=', 'users.id')
            ->whereIn('waiting_list.status', ['waiting', 'notified'])
            ->orderBy('waiting_list.queue_number', 'asc')
            ->get();

        return response()->json(['status' => 200, 'data' => $entries]);
    }

    /**
     * Admin panggil customer — update status + kirim FCM push notification.
     * PUT /admin/waiting-list/{id}/notify
     */
    public function notify($id)
    {
        $entry = DB::table('waiting_list')->where('id', $id)->first();

        if (!$entry) {
            return response()->json(['message' => 'Antrian tidak ditemukan'], 404);
        }

        if ($entry->status !== 'waiting') {
            return response()->json(['message' => 'Customer sudah dipanggil atau tidak aktif'], 400);
        }

        // Ambil FCM token — prioritas dari waiting_list, fallback ke users.fcm_token
        $fcmToken = $this->_getFcmTokenForEntry($entry);

        // Cari meja yang paling cocok (best-fit): kapasitas terkecil yang >= party_size
        $suggestedTable = DB::table('tables')
            ->where('status', 'available')
            ->where('capacity', '>=', $entry->party_size)
            ->orderBy('capacity', 'asc') // ambil yang paling pas (terkecil yang muat)
            ->first();

        // Update status antrian ke notified, simpan table_id, dan set meja jadi occupied
        DB::table('waiting_list')->where('id', $id)->update([
            'status'      => 'notified',
            'table_id'    => $suggestedTable?->id,
            'notified_at' => now(),
            'updated_at'  => now(),
        ]);

        if ($suggestedTable) {
            DB::table('tables')->where('id', $suggestedTable->id)->update(['status' => 'occupied']);
        }

        $tableInfo = $suggestedTable
            ? "Silakan menuju ke " . str_replace('JK-TABLE-', 'Meja ', $suggestedTable->qr_code_ref) . " (kapasitas {$suggestedTable->capacity} orang)."
            : 'Silakan menuju kasir, staf kami akan membantu Anda.';

        $fcmSuccess = false;
        if ($fcmToken) {
            $fcmSuccess = (new FcmService())->sendNotification(
                $fcmToken,
                'Meja Anda Sudah Siap! \u{1F4BA}',
                "Halo! Giliran Anda telah tiba. Nomor antrean #{$entry->queue_number}. {$tableInfo}",
                [
                    'queue_number' => (string) $entry->queue_number,
                    'type'         => 'waiting_list_called',
                    'table_number' => $suggestedTable ? str_replace('JK-TABLE-', 'Meja ', $suggestedTable->qr_code_ref) : '',
                    'table_id'     => (string) ($suggestedTable?->id ?? ''),
                ]
            );
        }

        return response()->json([
            'status'         => 200,
            'message'        => 'Customer berhasil dipanggil',
            'fcm_sent'       => $fcmSuccess,
            'fcm_missing'    => !$fcmToken,
            'suggested_table'=> $suggestedTable ? str_replace('JK-TABLE-', 'Meja ', $suggestedTable->qr_code_ref) : null,
        ]);
    }

    /**
     * Admin konfirmasi customer sudah duduk.
     * PUT /admin/waiting-list/{id}/seat
     */
    public function seat($id)
    {
        $entry = DB::table('waiting_list')->where('id', $id)->first();
        if (!$entry) return response()->json(['message' => 'Antrian tidak ditemukan'], 404);

        DB::table('waiting_list')->where('id', $id)->update([
            'status'     => 'seated',
            'updated_at' => now(),
        ]);

        $fcmToken = $this->_getFcmTokenForEntry($entry);
        if ($fcmToken) {
            (new FcmService())->sendNotification(
                $fcmToken,
                'Selamat Menikmati! \u{2615}',
                'Silakan memesan makanan atau minuman langsung dari meja Anda.',
                ['type' => 'waiting_list_seated']
            );
        }

        return response()->json(['status' => 200, 'message' => 'Customer sudah duduk']);
    }

    /**
     * Admin tandai expired (customer tidak datang setelah dipanggil).
     * PUT /admin/waiting-list/{id}/expire
     */
    public function expire($id)
    {
        $entry = DB::table('waiting_list')->where('id', $id)->first();
        if ($entry) {
            DB::table('waiting_list')->where('id', $id)->update([
                'status'     => 'expired',
                'updated_at' => now(),
            ]);

            if ($entry->table_id) {
                \App\Models\Table::syncStatus($entry->table_id);
            }

            $fcmToken = $this->_getFcmTokenForEntry($entry);
            if ($fcmToken) {
                (new FcmService())->sendNotification(
                    $fcmToken,
                    'Antrean Dibatalkan \u{274C}',
                    'Mohon maaf, antrean Anda hangus karena batas waktu panggilan telah lewat.',
                    ['type' => 'waiting_list_expired']
                );
            }
        }

        return response()->json(['status' => 200, 'message' => 'Antrian ditandai expired']);
    }
    // ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

    private function _getFcmTokenForEntry($entry): ?string
    {
        if ($entry->fcm_token) return $entry->fcm_token;
        $user = DB::table('users')->where('id', $entry->customer_id)->first();
        return $user?->fcm_token;
    }
}
