<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DisasterHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'location_name',
        'description',
        'event_time',
        'water_level_cm',
        'impact',
        'photo_path',
        'status',
        'verified_report_id',
    ];

    protected $casts = [
        'event_time' => 'datetime',
        'water_level_cm' => 'decimal:2',
    ];

    public function verifiedReport()
    {
        return $this->belongsTo(
            CitizenReport::class,
            'verified_report_id'
        );
    }
}