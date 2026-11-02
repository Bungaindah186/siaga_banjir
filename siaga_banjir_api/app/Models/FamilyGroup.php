<?php

namespace App\Models;

use App\Models\FamilyMember;
use App\Models\FamilyStatus;
use App\Models\FamilyMessage;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FamilyGroup extends Model
{
    protected $fillable = [
        'name',
        'invite_code',
        'created_by',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): HasMany
    {
        return $this->hasMany(FamilyMember::class);
    }

    public function statuses(): HasMany
    {
        return $this->hasMany(FamilyStatus::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(FamilyMessage::class);
    }
}