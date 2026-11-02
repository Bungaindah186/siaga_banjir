<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    /**
     * Mengambil profil pengguna yang sedang login.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'home_address' => $user->home_address,
                'home_latitude' => $user->home_latitude,
                'home_longitude' => $user->home_longitude,
                'profile_photo_path' => $user->profile_photo_path,
            ],
        ]);
    }

    /**
     * Memperbarui informasi profil dan lokasi rumah.
     */
    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'home_address' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'home_latitude' => [
                'sometimes',
                'nullable',
                'numeric',
                'between:-90,90',
            ],
            'home_longitude' => [
                'sometimes',
                'nullable',
                'numeric',
                'between:-180,180',
            ],
        ], [
            'name.required' => 'Nama lengkap wajib diisi.',
            'phone.max' => 'Nomor HP maksimal 30 karakter.',
            'home_address.max' => 'Alamat rumah terlalu panjang.',
            'home_latitude.numeric' => 'Latitude harus berupa angka.',
            'home_latitude.between' => 'Latitude harus antara -90 sampai 90.',
            'home_longitude.numeric' => 'Longitude harus berupa angka.',
            'home_longitude.between' => 'Longitude harus antara -180 sampai 180.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Data profil tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->fill($validator->validated());
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil disimpan.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'home_address' => $user->home_address,
                'home_latitude' => $user->home_latitude,
                'home_longitude' => $user->home_longitude,
                'profile_photo_path' => $user->profile_photo_path,
            ],
        ]);
    }

    /**
     * Mengunggah atau mengganti foto profil pengguna.
     */
    public function uploadPhoto(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'photo' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:2048',
            ],
        ], [
            'photo.required' => 'Silakan pilih foto terlebih dahulu.',
            'photo.image' => 'File harus berupa gambar.',
            'photo.mimes' => 'Format foto harus JPG, JPEG, PNG, atau WEBP.',
            'photo.max' => 'Ukuran foto maksimal 2 MB.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Foto profil tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        // Simpan foto baru.
        $path = $request->file('photo')->store('profile-photos', 'public');

        // Hapus foto lama jika masih tersimpan di disk public.
        if ($user->profile_photo_path) {
            Storage::disk('public')->delete($user->profile_photo_path);
        }

        // Simpan lokasi foto baru ke database.
        $user->profile_photo_path = $path;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Foto profil berhasil diperbarui.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'home_address' => $user->home_address,
                'home_latitude' => $user->home_latitude,
                'home_longitude' => $user->home_longitude,
                'profile_photo_path' => $user->profile_photo_path,
                'profile_photo_url' => asset('storage/' . $user->profile_photo_path),
            ],
        ]);
    }
}