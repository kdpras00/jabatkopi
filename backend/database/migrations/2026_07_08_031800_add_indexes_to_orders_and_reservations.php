<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Optimasi tabel orders
        Schema::table('orders', function (Blueprint $table) {
            $existing = collect(DB::select("
                SELECT indexname FROM pg_indexes WHERE tablename = 'orders'
            "))->pluck('indexname');

            if (!$existing->contains('orders_customer_id_index')) {
                $table->index('customer_id');
            }
            if (!$existing->contains('orders_table_id_index')) {
                $table->index('table_id');
            }
            if (!$existing->contains('orders_status_index')) {
                $table->index('status');
            }
        });

        // 2. Optimasi tabel reservations
        Schema::table('reservations', function (Blueprint $table) {
            $existing = collect(DB::select("
                SELECT indexname FROM pg_indexes WHERE tablename = 'reservations'
            "))->pluck('indexname');

            if (!$existing->contains('reservations_customer_id_index')) {
                $table->index('customer_id');
            }
            if (!$existing->contains('reservations_table_id_index')) {
                $table->index('table_id');
            }
            if (!$existing->contains('reservations_status_index')) {
                $table->index('status');
            }
            if (!$existing->contains('reservations_reservation_date_index')) {
                $table->index('reservation_date');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['customer_id']);
            $table->dropIndex(['table_id']);
            $table->dropIndex(['status']);
        });

        Schema::table('reservations', function (Blueprint $table) {
            $table->dropIndex(['customer_id']);
            $table->dropIndex(['table_id']);
            $table->dropIndex(['status']);
            $table->dropIndex(['reservation_date']);
        });
    }
};
