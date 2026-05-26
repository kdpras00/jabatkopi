<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Reservation extends Model
{
    use SoftDeletes;

    protected $table = 'reservations';

    protected $fillable = [
        'customer_id',
        'table_id',
        'reservation_date',
        'pax',
        'status',
        'time_start',
        'time_end',
        'barcode',
        'checked_in_at',
        'completed_at',
        'notes',
        'cancel_reason',
    ];

    protected $casts = [
        'reservation_date' => 'datetime',
        'time_start' => 'datetime',
        'time_end' => 'datetime',
        'checked_in_at' => 'datetime',
        'completed_at' => 'datetime',
        'pax' => 'integer',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(Table::class, 'table_id');
    }
}
