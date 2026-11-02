<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('family_members', function (Blueprint $table) {
            $table->id();

            // Kelompok keluarga yang diikuti
            $table->foreignId('family_group_id')
                ->constrained('family_groups')
                ->cascadeOnDelete();

            // Akun pengguna yang menjadi anggota
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Peran pengguna dalam kelompok keluarga
            $table->string('role')->default('member');

            $table->timestamps();

            // Satu akun hanya boleh tercatat sekali
            // dalam kelompok keluarga yang sama.
            $table->unique(['family_group_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('family_members');
    }
};