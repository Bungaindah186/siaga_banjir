<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FamilyGroup;
use App\Models\FamilyMember;
use App\Models\FamilyMessage;
use App\Models\FamilyMessageRead;
use Illuminate\Http\Request;

class FamilyChatController extends Controller
{
    /**
     * Mengambil riwayat pesan dalam grup keluarga.
     * Pesan yang belum dibaca oleh pengguna ditandai sudah dibaca.
     */
    public function index(Request $request, int $groupId)
    {
        $user = $request->user();

        $isMember = FamilyMember::where('family_group_id', $groupId)
            ->where('user_id', $user->id)
            ->exists();

        if (! $isMember) {
            return response()->json([
                'message' => 'Kamu bukan anggota grup keluarga ini.',
            ], 403);
        }

        // Tandai pesan yang diterima pengguna sebagai sudah dibaca.
        FamilyMessageRead::where('user_id', $user->id)
            ->whereNull('read_at')
            ->whereHas('familyMessage', function ($query) use ($groupId) {
                $query->where('family_group_id', $groupId);
            })
            ->update([
                'read_at' => now(),
                'updated_at' => now(),
            ]);

        $messages = FamilyMessage::with('user:id,name')
            ->where('family_group_id', $groupId)
            ->orderBy('sent_at')
            ->orderBy('id')
            ->get();

        return response()->json([
            'message' => 'Riwayat chat berhasil diambil.',
            'data' => $messages,
        ]);
    }

    /**
     * Mengirim pesan ke grup keluarga.
     */
    public function store(Request $request, int $groupId)
    {
        $validated = $request->validate([
            'message' => ['required', 'string', 'max:5000'],
        ]);

        $user = $request->user();

        $isMember = FamilyMember::where('family_group_id', $groupId)
            ->where('user_id', $user->id)
            ->exists();

        if (! $isMember) {
            return response()->json([
                'message' => 'Kamu bukan anggota grup keluarga ini.',
            ], 403);
        }

        $groupExists = FamilyGroup::whereKey($groupId)->exists();

        if (! $groupExists) {
            return response()->json([
                'message' => 'Grup keluarga tidak ditemukan.',
            ], 404);
        }

        $message = FamilyMessage::create([
            'family_group_id' => $groupId,
            'user_id' => $user->id,
            'message' => $validated['message'],
            'sent_at' => now(),
        ]);

        // Buat status belum dibaca untuk setiap anggota selain pengirim.
        $otherMembers = FamilyMember::where('family_group_id', $groupId)
            ->where('user_id', '!=', $user->id)
            ->get(['user_id']);

        foreach ($otherMembers as $member) {
            FamilyMessageRead::create([
                'family_message_id' => $message->id,
                'user_id' => $member->user_id,
                'read_at' => null,
            ]);
        }

        $message->load('user:id,name');

        return response()->json([
            'message' => 'Pesan berhasil dikirim.',
            'data' => $message,
        ], 201);
    }

    /**
     * Menghitung seluruh pesan belum dibaca oleh pengguna yang login.
     */
    public function unreadCount(Request $request)
    {
        $count = FamilyMessageRead::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'message' => 'Jumlah pesan belum dibaca berhasil diambil.',
            'unread_count' => $count,
        ]);
    }
}