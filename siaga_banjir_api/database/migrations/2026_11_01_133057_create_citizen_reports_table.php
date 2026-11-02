<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('citizen_reports', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('event_type');
            $table->string('location_name');

            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            $table->text('description');

            $table->string('event_time')->nullable();
            $table->decimal('water_level_cm', 8, 2)->nullable();

            $table->string('photo_path')->nullable();

            $table->string('status')->default('Menunggu Verifikasi');

            $table->text('officer_notes')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('citizen_reports');
    }
};