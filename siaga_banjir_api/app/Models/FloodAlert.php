<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FloodAlert extends Model
{
    protected $fillable = [
        'region_name',
        'status',
        'title',
        'description',
        'water_level_cm',
        'rise_rate_cm_per_hour',
        'reported_by',
        'is_active',
        'latitude',
        'longitude',
    ];

    protected function casts(): array
    {
        return [
            'water_level_cm' => 'decimal:2',
            'rise_rate_cm_per_hour' => 'decimal:2',
            'is_active' => 'boolean',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_by');
    }
}