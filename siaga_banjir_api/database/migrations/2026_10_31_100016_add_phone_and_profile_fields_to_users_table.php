<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Kolom phone, home_address, dan profile_photo_path
        // sudah tersedia di tabel users.
        // Tidak perlu menambahkan kolom lagi.
    }

    public function down(): void
    {
        // Kolom tidak dihapus karena sudah ada sebelumnya.
    }
};