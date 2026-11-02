<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('family_statuses', function (Blueprint $table) {
            $table->id();

            // Anggota keluarga yang mengirim status
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Kelompok keluarga tempat status dilaporkan
            $table->foreignId('family_group_id')
                ->constrained('family_groups')
                ->cascadeOnDelete();

            // Status keselamatan anggota keluarga
            $table->enum('status', [
                'aman',
                'waspada',
                'darurat',
                'butuh_bantuan',
            ]);

            // Pesan tambahan, jika ada
            $table->text('message')->nullable();

            // Waktu status dilaporkan
            $table->timestamp('reported_at')->useCurrent();

            $table->timestamps();

            // Mempermudah pencarian status terbaru per kelompok
            $table->index(['family_group_id', 'reported_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('family_statuses');
    }
};