<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('family_invitations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('family_group_id')
                ->constrained('family_groups')
                ->cascadeOnDelete();

            $table->foreignId('invited_by')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->foreignId('invited_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('status')->default('pending');
            $table->timestamp('responded_at')->nullable();

            $table->timestamps();

            $table->index(
                ['invited_user_id', 'status'],
                'family_invitations_recipient_status_index'
            );

            $table->index(
                ['family_group_id', 'status'],
                'family_invitations_group_status_index'
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('family_invitations');
    }
};