<?php
use App\Http\Controllers\FloodAlertController;
use App\Http\Controllers\BmkgWeatherController;
use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\EvacuationPointController;
use App\Http\Controllers\Api\FamilyInvitationController;
use App\Http\Controllers\Api\FamilyController;
use App\Http\Controllers\Api\FamilyChatController;
use App\Http\Controllers\Api\NotificationPreferenceController;
use App\Http\Controllers\Api\UserDeviceController;
use App\Http\Controllers\Api\RiverReadingController;
use App\Http\Controllers\Api\CitizenReportController;

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:6,1');
Route::get('/weather', [BmkgWeatherController::class, 'show']);
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:6,1');
Route::middleware('auth:sanctum')->group(function () {
    // Kelompok keluarga
        Route::get('/family/groups', [FamilyController::class, 'groups']);

        Route::post('/family/groups', [FamilyController::class, 'createGroup']);

        Route::post('/family/groups/join', [FamilyController::class, 'joinGroup']);
    // Undangan keluarga
        Route::post('/family/invitations', [FamilyInvitationController::class, 'store']);
        Route::get('/family/invitations', [FamilyInvitationController::class, 'index']);
        Route::post('/family/invitations/{invitation}/accept', [FamilyInvitationController::class, 'accept']);
        Route::post('/family/invitations/{invitation}/reject', [FamilyInvitationController::class, 'reject']);
        Route::delete(
            '/family/groups/leave',
            [FamilyController::class, 'leaveGroup']
        );
        // Kelompok keluarga
        Route::get('/family/groups', [FamilyController::class, 'groups']);

        Route::post('/family/groups', [FamilyController::class, 'createGroup']);

        Route::post('/family/groups/join', [FamilyController::class, 'joinGroup']);
        // Chat keluarga
            Route::get('/family/unread-count', [FamilyChatController::class, 'unreadCount']);
            Route::get(
                '/family/groups/{groupId}/messages',
                [FamilyChatController::class, 'index']
            );

            Route::post(
                '/family/groups/{groupId}/messages',
                [FamilyChatController::class, 'store']
            );

        // Status keselamatan keluarga
        Route::get('/family/status', [FamilyController::class, 'statuses']);

        Route::post('/family/status', [FamilyController::class, 'sendStatus']);
    // Profil
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/photo', [ProfileController::class, 'uploadPhoto']);

    // Notifikasi

    // Preferensi Notifikasi
    Route::get(
        '/notification-preferences',
        [NotificationPreferenceController::class, 'show']
    );

    Route::put(
        '/notification-preferences',
        [NotificationPreferenceController::class, 'update']
    );
    Route::get('/notifications', [NotificationController::class, 'index']);

    // Pendaftaran perangkat untuk push notification
    Route::post(
        '/device-tokens',
        [UserDeviceController::class, 'store']
    );

    Route::delete(
        '/device-tokens',
        [UserDeviceController::class, 'destroy']
    );

    // Titik Pengungsian
    Route::get('/evacuation-points', [EvacuationPointController::class, 'index']);

    Route::patch(
        '/notifications/{id}/read',
        [NotificationController::class, 'markAsRead']
    );

    Route::delete(
        '/notifications/{id}',
        [NotificationController::class, 'destroy']
    );

    Route::delete(
        '/notifications',
        [NotificationController::class, 'destroyAll']
    );
    // Riwayat dan input pengukuran ketinggian sungai
    Route::get('/river-readings', [RiverReadingController::class, 'index']);
    Route::post('/river-readings', [RiverReadingController::class, 'store']);

    // Lapor Warga
    Route::post('/citizen-reports', [CitizenReportController::class, 'store']);
    Route::get('/citizen-reports/my', [CitizenReportController::class, 'myReports']);
});
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
Route::get('/disaster-histories', [
    \App\Http\Controllers\Api\DisasterHistoryController::class,
    'index'
]);

Route::get('/disaster-histories/{id}', [
    \App\Http\Controllers\Api\DisasterHistoryController::class,
    'show'
]);

Route::get('/flood-alerts', [FloodAlertController::class, 'index']);