<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FamilyGroup;
use App\Models\FamilyMember;
use App\Models\FamilyStatus;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FamilyController extends Controller
{
    /**
     * Menampilkan grup keluarga milik pengguna yang sedang login.
     */
    public function groups(Request $request)
    {
        $groups = FamilyGroup::whereHas('members', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })
            ->with(['members'])
            ->latest()
            ->get()
            ->map(function ($group) {
                return [
                    'id' => $group->id,
                    'name' => $group->name,
                    'invite_code' => $group->invite_code,
                    'members_count' => $group->members->count(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $groups,
        ]);
    }

    /**
     * Membuat grup keluarga dan memasukkan pembuat sebagai anggota.
     */
    public function createGroup(Request $request)
    {
        $alreadyInGroup = FamilyMember::where(
    'user_id',
    $request->user()->id
)->exists();

if ($alreadyInGroup) {
    return response()->json([
        'success' => false,
        'message' => 'Kamu sudah tergabung dalam grup keluarga. Kamu tidak dapat membuat grup baru.',
    ], 422);
}
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
        ]);

        $group = DB::transaction(function () use ($request, $validated) {
            do {
                $inviteCode = Str::upper(Str::random(8));
            } while (FamilyGroup::where('invite_code', $inviteCode)->exists());

            $group = FamilyGroup::create([
                'name' => $validated['name'],
                'invite_code' => $inviteCode,
                'created_by' => $request->user()->id,
            ]);

            FamilyMember::create([
                'family_group_id' => $group->id,
                'user_id' => $request->user()->id,
                'role' => 'admin',
            ]);

            return $group;
        });

        return response()->json([
            'success' => true,
            'message' => 'Grup keluarga berhasil dibuat.',
            'data' => $group,
        ], 201);
    }

    /**
     * Bergabung ke grup menggunakan kode undangan.
     */
    public function joinGroup(Request $request)
    {
        $validated = $request->validate([
            'invite_code' => ['required', 'string', 'max:12'],
        ]);

        $group = FamilyGroup::where(
            'invite_code',
            Str::upper(trim($validated['invite_code']))
        )->first();

        if (!$group) {
            return response()->json([
                'success' => false,
                'message' => 'Kode undangan keluarga tidak ditemukan.',
            ], 404);
        }

        FamilyMember::firstOrCreate([
            'family_group_id' => $group->id,
            'user_id' => $request->user()->id,
        ], [
            'role' => 'member',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Berhasil bergabung dengan keluarga.',
            'data' => [
                'id' => $group->id,
                'name' => $group->name,
                'invite_code' => $group->invite_code,
            ],
        ]);
    }

    /**
     * Menampilkan status terbaru setiap anggota dalam satu grup.
     */
    public function statuses(Request $request)
    {
        $validated = $request->validate([
            'family_group_id' => ['required', 'integer', 'exists:family_groups,id'],
        ]);

        $groupId = (int) $validated['family_group_id'];
        $userId = $request->user()->id;

        $isMember = FamilyMember::where('family_group_id', $groupId)
            ->where('user_id', $userId)
            ->exists();

        if (!$isMember) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu bukan anggota grup keluarga ini.',
            ], 403);
        }

        $members = FamilyMember::where('family_group_id', $groupId)
            ->with('user:id,name')
            ->get();

        $data = $members->map(function ($member) use ($groupId) {
            $latestStatus = FamilyStatus::where('family_group_id', $groupId)
                ->where('user_id', $member->user_id)
                ->latest('reported_at')
                ->latest('id')
                ->first();

            return [
                'user_id' => $member->user_id,
                'name' => $member->user->name ?? 'Anggota keluarga',
                'status' => $latestStatus?->status,
                'message' => $latestStatus?->message,
                'reported_at' => $latestStatus?->reported_at?->toISOString(),
            ];
        });

        return response()->json([
            'success' => true,
            'family_group_id' => $groupId,
            'data' => $data,
        ]);
    }

    /**
     * Menyimpan status terbaru anggota keluarga.
     */
    public function sendStatus(Request $request)
    {
        $validated = $request->validate([
            'family_group_id' => ['required', 'integer', 'exists:family_groups,id'],
            'status' => ['required', 'in:aman,waspada,darurat,butuh_bantuan'],
            'message' => ['nullable', 'string', 'max:1000'],
        ]);

        $userId = $request->user()->id;
        $groupId = (int) $validated['family_group_id'];

        $isMember = FamilyMember::where('family_group_id', $groupId)
            ->where('user_id', $userId)
            ->exists();

        if (!$isMember) {
            return response()->json([
                'success' => false,
                'message' => 'Kamu bukan anggota grup keluarga ini.',
            ], 403);
        }

        $status = FamilyStatus::create([
            'user_id' => $userId,
            'family_group_id' => $groupId,
            'status' => $validated['status'],
            'message' => $validated['message'] ?? null,
            'reported_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status keluarga berhasil dikirim.',
            'data' => $status->load('user:id,name'),
        ], 201);
    }
    /**
     * Menghapus keanggotaan pengguna dari grup keluarga.
     * Jika admin keluar, anggota yang tersisa akan menjadi admin.
     * Jika anggota terakhir keluar, grup keluarga akan dihapus.
     */
    public function leaveGroup(Request $request)
    {
        $validated = $request->validate([
            'family_group_id' => [
                'required',
                'integer',
                'exists:family_groups,id',
            ],
        ]);

        $userId = $request->user()->id;
        $groupId = (int) $validated['family_group_id'];

        $result = DB::transaction(function () use ($userId, $groupId) {
            $group = FamilyGroup::whereKey($groupId)
                ->lockForUpdate()
                ->first();

            if (!$group) {
                return [
                    'success' => false,
                    'status' => 404,
                    'message' => 'Grup keluarga tidak ditemukan.',
                ];
            }

            $membership = FamilyMember::where('family_group_id', $groupId)
                ->where('user_id', $userId)
                ->first();

            if (!$membership) {
                return [
                    'success' => false,
                    'status' => 404,
                    'message' => 'Kamu bukan anggota grup keluarga ini.',
                ];
            }

            // Hapus keanggotaan pengguna yang ingin keluar.
            $membership->delete();

            // Cari anggota yang masih tersisa.
            $remainingMembers = FamilyMember::where(
                'family_group_id',
                $groupId
            )
                ->orderBy('id')
                ->get();

            // Jika tidak ada anggota tersisa, hapus grup.
            if ($remainingMembers->isEmpty()) {
                // Hapus status keluarga milik grup terlebih dahulu.
                FamilyStatus::where('family_group_id', $groupId)->delete();

                $group->delete();

                return [
                    'success' => true,
                    'status' => 200,
                    'message' => 'Kamu keluar dari grup. Grup keluarga telah dihapus karena tidak memiliki anggota.',
                    'group_deleted' => true,
                ];
            }

            // Jika anggota yang tersisa tidak memiliki admin,
            // jadikan anggota pertama sebagai admin baru.
            $hasAdmin = $remainingMembers->contains(
                fn ($member) => $member->role === 'admin'
            );

            if (!$hasAdmin) {
                $newAdmin = $remainingMembers->first();

                $newAdmin->role = 'admin';
                $newAdmin->save();
            }

            return [
                'success' => true,
                'status' => 200,
                'message' => 'Kamu berhasil keluar dari grup keluarga.',
                'group_deleted' => false,
            ];
        });

        return response()->json(
            collect($result)->except('status')->all(),
            $result['status']
        );
    }
}