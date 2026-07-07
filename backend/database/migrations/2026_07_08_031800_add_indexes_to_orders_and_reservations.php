<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Optimasi tabel orders
        Schema::table('orders', function (Blueprint $table) {
            // Kita cek dulu jika index belum ada, baru kita buat agar aman dari error
            $schemaManager = Schema::getConnection()->getDoctrineSchemaManager();
            $indexes = $schemaManager->listTableIndexes('orders');

            if (!array_key_exists('orders_customer_id_index', $indexes)) {
                $table->index('customer_id');
            }
            if (!array_key_exists('orders_table_id_index', $indexes)) {
                $table->index('table_id');
            }
            if (!array_key_exists('orders_status_index', $indexes)) {
                $table->index('status');
            }
        });

        // 2. Optimasi tabel reservations
        Schema::table('reservations', function (Blueprint $table) {
            $schemaManager = Schema::getConnection()->getDoctrineSchemaManager();
            $indexes = $schemaManager->listTableIndexes('reservations');

            if (!array_key_exists('reservations_customer_id_index', $indexes)) {
                $table->index('customer_id');
            }
            if (!array_key_exists('reservations_table_id_index', $indexes)) {
                $table->index('table_id');
            }
            if (!array_key_exists('reservations_status_index', $indexes)) {
                $table->index('status');
            }
            if (!array_key_exists('reservations_reservation_date_index', $indexes)) {
                $table->index('reservation_date');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
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
