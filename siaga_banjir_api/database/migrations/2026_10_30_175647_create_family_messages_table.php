<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('family_messages', function (Blueprint $table) {
            $table->id();

            // Kelompok keluarga tempat pesan dikirim
            $table->foreignId('family_group_id')
                ->constrained('family_groups')
                ->cascadeOnDelete();

            // Pengguna yang mengirim pesan
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Isi pesan
            $table->text('message');

            // Waktu pesan dikirim
            $table->timestamp('sent_at')->useCurrent();

            $table->timestamps();

            // Mempermudah pengambilan pesan berdasarkan waktu
            $table->index(['family_group_id', 'sent_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('family_messages');
    }
};