<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CitizenReport extends Model
{
    protected $fillable = [
        'user_id',
        'event_type',
        'location_name',
        'latitude',
        'longitude',
        'description',
        'event_time',
        'water_level_cm',
        'photo_path',
        'status',
        'officer_notes',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'water_level_cm' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}