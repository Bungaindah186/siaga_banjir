<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('river_readings', function (Blueprint $table) {
            $table->id();

            // Lokasi pemantauan
            $table->foreignId('flood_alert_id')
                ->constrained('flood_alerts')
                ->cascadeOnDelete();

            // Data pengukuran air
            $table->decimal('water_level_cm', 8, 2);
            $table->decimal('rise_rate_cm_per_hour', 8, 2)->nullable();

            // Petugas yang melakukan pengukuran
            $table->foreignId('recorded_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            // Waktu pengukuran
            $table->timestamp('measured_at');

            $table->timestamps();

            $table->index(['flood_alert_id', 'measured_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('river_readings');
    }
};