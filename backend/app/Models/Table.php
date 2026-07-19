<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Table extends Model
{
    use SoftDeletes;

    protected $table = 'tables';

    protected $fillable = [
        'qr_code_ref',
        'status',
        'capacity',
    ];

    /**
     * Sinkronisasi status meja secara otomatis berdasarkan order aktif.
     * Meja menjadi 'occupied' jika ada minimal 1 order aktif, dan 'available' jika tidak ada.
     */
    public static function syncStatus($tableId): void
    {
        if (!$tableId) return;

        $hasActiveOrder = \Illuminate\Support\Facades\DB::table('orders')
            ->where('table_id', $tableId)
            ->whereIn('status', ['pending', 'processing', 'preparing', 'ready'])
            ->whereNull('deleted_at')
            ->exists();

        self::where('id', $tableId)->update([
            'status'     => $hasActiveOrder ? 'occupied' : 'available',
            'updated_at' => now(),
        ]);
    }
}
