<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('waiting_list', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            // Nomor antrean harian — di-generate saat insert
            $table->integer('queue_number');
            $table->integer('party_size')->default(1);
            // waiting = menunggu, notified = sudah dipanggil, seated = sudah duduk
            // cancelled = dibatalkan customer, expired = tidak datang setelah dipanggil
            $table->string('status')->default('waiting');
            // FCM device token customer untuk push notification
            $table->text('fcm_token')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('notified_at')->nullable();
            $table->timestamps();

            $table->index('customer_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('waiting_list');
    }
};
