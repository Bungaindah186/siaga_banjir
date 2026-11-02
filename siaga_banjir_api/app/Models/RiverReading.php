<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RiverReading extends Model
{
    protected $fillable = [
        'flood_alert_id',
        'water_level_cm',
        'rise_rate_cm_per_hour',
        'recorded_by',
        'measured_at',
    ];

    protected function casts(): array
    {
        return [
            'water_level_cm' => 'decimal:2',
            'rise_rate_cm_per_hour' => 'decimal:2',
            'measured_at' => 'datetime',
        ];
    }

    public function floodAlert(): BelongsTo
    {
        return $this->belongsTo(FloodAlert::class);
    }

    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}