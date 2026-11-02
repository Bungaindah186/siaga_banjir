<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('evacuation_points', function (Blueprint $table) {
            $table->id();

            $table->string('name');
            $table->text('address')->nullable();

            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            $table->unsignedInteger('capacity')->nullable();
            $table->unsignedInteger('current_occupancy')->nullable();

            $table->enum('status', [
                'active',
                'full',
                'closed',
            ])->default('active');

            $table->text('description')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('evacuation_points');
    }
};