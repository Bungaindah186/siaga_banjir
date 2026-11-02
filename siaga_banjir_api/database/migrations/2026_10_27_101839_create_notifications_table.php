<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();

            // Pengguna yang menerima notifikasi
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Sumber notifikasi, misalnya peringatan banjir
            $table->foreignId('flood_alert_id')
                ->nullable()
                ->constrained('flood_alerts')
                ->nullOnDelete();

            // Informasi notifikasi
            $table->string('type')->default('general');
            $table->string('title');
            $table->text('message');

            // Status baca
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            $table->index(['user_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};