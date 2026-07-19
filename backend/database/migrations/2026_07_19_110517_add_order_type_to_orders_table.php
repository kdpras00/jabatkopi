<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Tipe pesanan: dine_in (makan di tempat), pickup (ambil sendiri), takeaway (dibawa pulang)
            $table->string('order_type')->default('dine_in')->after('staff_name');
            // Waktu pengambilan untuk tipe pickup, mis: "14:30"
            $table->string('pickup_time')->nullable()->after('order_type');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['order_type', 'pickup_time']);
        });
    }
};
