<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('river_readings', function (Blueprint $table) {
            $table->foreignId('flood_alert_id')
                ->after('id')
                ->constrained('flood_alerts')
                ->cascadeOnDelete();

            $table->decimal('water_level_cm', 8, 2);

            $table->decimal('rise_rate_cm_per_hour', 8, 2)
                ->nullable();

            $table->foreignId('recorded_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamp('measured_at');

            $table->index(['flood_alert_id', 'measured_at']);
        });
    }

    public function down(): void
    {
        Schema::table('river_readings', function (Blueprint $table) {
            $table->dropForeign(['flood_alert_id']);
            $table->dropForeign(['recorded_by']);
            $table->dropIndex(['flood_alert_id', 'measured_at']);

            $table->dropColumn([
                'flood_alert_id',
                'water_level_cm',
                'rise_rate_cm_per_hour',
                'recorded_by',
                'measured_at',
            ]);
        });
    }
};