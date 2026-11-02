<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FamilyGroup;
use App\Models\FamilyInvitation;
use App\Models\FamilyMember;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class FamilyInvitationController extends Controller
{
    /**
     * Mengirim undangan ke pengguna yang terdaftar berdasarkan nomor HP.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'phone' => ['required', 'string', 'max:30'],
        ]);

        $currentUser = $request->user();
        $phone = preg_replace('/[\s\-()]+/', '', $validated['phone']);

        if (!$phone) {
            throw ValidationException::withMessages([
                'phone' => 'Nomor HP tidak valid.',
            ]);
        }

        $recipient = \App\Models\User::where('phone', $phone)->first();

        if (!$recipient) {
            return response()->json([
                'message' => 'Nomor HP belum terdaftar di SiagaBanjir.',
            ], 404);
        }

        if ($recipient->id === $currentUser->id) {
            return response()->json([
                'message' => 'Kamu tidak dapat mengundang akun sendiri.',
            ], 422);
        }

        return DB::transaction(function () use ($currentUser, $recipient) {
            $membership = FamilyMember::where('user_id', $currentUser->id)
                ->lockForUpdate()
                ->first();

            if (!$membership) {
                return response()->json([
                    'message' => 'Kamu belum tergabung dalam grup keluarga.',
                ], 422);
            }

            $group = FamilyGroup::find($membership->family_group_id);

            if (!$group) {
                return response()->json([
                    'message' => 'Grup keluarga tidak ditemukan.',
                ], 404);
            }

            if (FamilyMember::where('family_group_id', $group->id)
                ->where('user_id', $recipient->id)
                ->exists()) {
                return response()->json([
                    'message' => 'Pengguna tersebut sudah menjadi anggota grup keluarga.',
                ], 422);
            }

            $existingInvitation = FamilyInvitation::where(
                'family_group_id',
                $group->id
            )
                ->where('invited_user_id', $recipient->id)
                ->where('status', 'pending')
                ->first();

            if ($existingInvitation) {
                return response()->json([
                    'message' => 'Undangan untuk pengguna tersebut masih menunggu jawaban.',
                ], 422);
            }

            $invitation = FamilyInvitation::create([
                'family_group_id' => $group->id,
                'invited_by' => $currentUser->id,
                'invited_user_id' => $recipient->id,
                'status' => 'pending',
            ]);

            Notification::create([
                'user_id' => $recipient->id,
                'type' => 'family_invitation',
                'title' => 'Undangan Keluarga',
                'message' => $currentUser->name
                    . ' mengundang kamu bergabung dengan grup keluarga '
                    . $group->name . '.',
            ]);

            return response()->json([
                'message' => 'Undangan keluarga berhasil dikirim.',
                'data' => [
                    'id' => $invitation->id,
                    'family_group' => $group->name,
                    'recipient' => $recipient->name,
                    'status' => $invitation->status,
                ],
            ], 201);
        });
    }

    /**
     * Menampilkan undangan masuk milik pengguna yang sedang login.
     */
    public function index(Request $request)
    {
        $invitations = FamilyInvitation::with([
            'familyGroup:id,name',
            'inviter:id,name',
        ])
            ->where('invited_user_id', $request->user()->id)
            ->where('status', 'pending')
            ->latest()
            ->get()
            ->map(function ($invitation) {
                return [
                    'id' => $invitation->id,
                    'family_group_id' => $invitation->family_group_id,
                    'family_group_name' => $invitation->familyGroup?->name,
                    'invited_by' => $invitation->inviter?->name,
                    'status' => $invitation->status,
                    'created_at' => $invitation->created_at,
                ];
            });

        return response()->json([
            'data' => $invitations,
        ]);
    }

    /**
     * Menerima undangan dan menambahkan pengguna ke grup.
     */
    public function accept(Request $request, FamilyInvitation $invitation)
    {
        return DB::transaction(function () use ($request, $invitation) {
            $invitation = FamilyInvitation::whereKey($invitation->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($invitation->invited_user_id !== $request->user()->id) {
                return response()->json([
                    'message' => 'Kamu tidak berhak menerima undangan ini.',
                ], 403);
            }

            if ($invitation->status !== 'pending') {
                return response()->json([
                    'message' => 'Undangan ini sudah diproses.',
                ], 422);
            }

            $existingMembership = FamilyMember::where(
                'user_id',
                $request->user()->id
            )->first();

            if ($existingMembership) {
                if ($existingMembership->family_group_id !== $invitation->family_group_id) {
                    return response()->json([
                        'message' => 'Kamu sudah tergabung dalam grup keluarga lain. Keluar dari grup tersebut sebelum menerima undangan ini.',
                    ], 422);
                }

                $invitation->update([
                    'status' => 'accepted',
                    'responded_at' => now(),
                ]);

                return response()->json([
                    'message' => 'Kamu sudah menjadi anggota grup keluarga ini.',
                ]);
            }

            $groupExists = FamilyGroup::whereKey(
                $invitation->family_group_id
            )->exists();

            if (!$groupExists) {
                return response()->json([
                    'message' => 'Grup keluarga sudah tidak tersedia.',
                ], 404);
            }

            FamilyMember::create([
                'family_group_id' => $invitation->family_group_id,
                'user_id' => $request->user()->id,
                'role' => 'member',
            ]);

            $invitation->update([
                'status' => 'accepted',
                'responded_at' => now(),
            ]);

            Notification::create([
                'user_id' => $invitation->invited_by,
                'type' => 'family_invitation_accepted',
                'title' => 'Undangan Diterima',
                'message' => $request->user()->name
                    . ' menerima undangan keluarga.',
            ]);

            return response()->json([
                'message' => 'Undangan diterima. Kamu berhasil bergabung dengan grup keluarga.',
            ]);
        });
    }

    /**
     * Menolak undangan tanpa mengubah keanggotaan grup.
     */
    public function reject(Request $request, FamilyInvitation $invitation)
    {
        if ($invitation->invited_user_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Kamu tidak berhak menolak undangan ini.',
            ], 403);
        }

        if ($invitation->status !== 'pending') {
            return response()->json([
                'message' => 'Undangan ini sudah diproses.',
            ], 422);
        }

        $invitation->update([
            'status' => 'rejected',
            'responded_at' => now(),
        ]);

        Notification::create([
            'user_id' => $invitation->invited_by,
            'type' => 'family_invitation_rejected',
            'title' => 'Undangan Ditolak',
            'message' => $request->user()->name
                . ' menolak undangan keluarga.',
        ]);

        return response()->json([
            'message' => 'Undangan ditolak.',
        ]);
    }
}