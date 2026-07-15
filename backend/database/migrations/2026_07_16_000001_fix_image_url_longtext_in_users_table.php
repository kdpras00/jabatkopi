<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Fix: image_url was VARCHAR(255) which is too short for base64-encoded images.
     * Change to LONGTEXT to support storing base64 images from Flutter app.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->longText('image_url')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('image_url')->nullable()->change();
        });
    }
};
