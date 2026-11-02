<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'name',
    'email',
    'password',
    'phone',
    'home_address',
    'home_latitude',
    'home_longitude',
    'profile_photo_path',
    'notification_alert',
    'notification_river',
    'notification_education',
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'home_latitude' => 'decimal:7',
            'home_longitude' => 'decimal:7',
            'notification_alert' => 'boolean',
            'notification_river' => 'boolean',
            'notification_education' => 'boolean',
        ];
    }
    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }
}