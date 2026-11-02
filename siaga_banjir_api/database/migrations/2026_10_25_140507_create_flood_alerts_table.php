<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
       Schema::create('flood_alerts', function (Blueprint $table) {
    $table->id();

    // Informasi wilayah dan kejadian
    $table->string('region_name');
    $table->string('status');
    $table->string('title');
    $table->text('description')->nullable();

    // Data ketinggian air, jika tersedia
    $table->decimal('water_level_cm', 8, 2)->nullable();
    $table->decimal('rise_rate_cm_per_hour', 8, 2)->nullable();

    // Petugas yang melaporkan kejadian
    $table->foreignId('reported_by')
        ->nullable()
        ->constrained('users')
        ->nullOnDelete();

    $table->boolean('is_active')->default(true);

    // Waktu pembuatan dan pembaruan data
    $table->timestamps();

    $table->index(['region_name', 'created_at']);
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('flood_alerts');
    }
};