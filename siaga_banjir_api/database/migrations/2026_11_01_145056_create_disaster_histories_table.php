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
    Schema::create('disaster_histories', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->string('location_name');
        $table->text('description');
        $table->dateTime('event_time');
        $table->decimal('water_level_cm', 8, 2)->nullable();
        $table->text('impact')->nullable();
        $table->string('photo_path')->nullable();
        $table->enum('status', ['Dalam Penanganan', 'Selesai'])
            ->default('Dalam Penanganan');
        $table->foreignId('verified_report_id')
            ->nullable()
            ->constrained('citizen_reports')
            ->nullOnDelete();
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('disaster_histories');
    }
};