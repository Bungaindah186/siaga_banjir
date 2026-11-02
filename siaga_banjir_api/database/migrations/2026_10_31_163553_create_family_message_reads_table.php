<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('family_message_reads', function (Blueprint $table) {
            $table->id();

            // Pesan yang status bacanya dicatat
            $table->foreignId('family_message_id')
                ->constrained('family_messages')
                ->cascadeOnDelete();

            // Pengguna yang membaca pesan
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Null berarti belum dibaca
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            // Satu pesan hanya memiliki satu status baca per pengguna
            $table->unique(['family_message_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('family_message_reads');
    }
};