<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = DB::table('users')->where('email', $request->email)->first();
        if (!$user) return response()->json(['message' => 'Email tidak ditemukan'], 404);
        if (!Hash::check($request->password, $user->password_hash)) {
            return response()->json(['message' => 'Email atau password salah'], 401);
        }
        $token = 'session_' . $user->id . '_' . time();
        return response()->json([
            'status' => 200,
            'message' => 'Berhasil masuk!',
            'data' => [
                'id' => $user->id,
                'token' => $token,
                'role' => $user->role ?? 'customer',
                'username' => $user->username ?? 'User',
            ]
        ]);
    }

    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required', 'username' => 'required',
            'email' => 'required|email', 'password' => 'required'
        ]);
        $existing = DB::table('users')
            ->where('username', $request->username)
            ->orWhere('email', $request->email)->first();
        if ($existing) return response()->json(['message' => 'Username/Email sudah terdaftar'], 400);

        DB::table('users')->insert([
            'name' => $request->name,
            'username' => $request->username,
            'email' => $request->email,
            'password_hash' => Hash::make($request->password),
            'role' => 'customer',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        return response()->json(['status' => 201, 'message' => 'Pendaftaran berhasil!']);
    }

    public function profile(Request $request)
    {
        $customerId = $request->header('X-User-Id');
        $user = DB::table('users')->where('id', $customerId)->first();
        return response()->json([
            'status' => 200,
            'data' => [
                'id' => $user->id,
                'name' => $user->name ?? '',
                'username' => $user->username ?? '',
                'email' => $user->email ?? '',
                'image_url' => $user->image_url ?? '',
                'role' => $user->role ?? 'customer',
            ]
        ]);
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
        ]);

        $customerId = $request->header('X-User-Id');
        DB::table('users')->where('id', $customerId)->update([
            'name' => $request->name,
            'username' => $request->username,
            'email' => $request->email,
            'image_url' => $request->image_url,
            'updated_at' => now(),
        ]);
        return response()->json(['status' => 200, 'message' => 'Profil berhasil diperbarui!']);
    }

    public function updatePassword(Request $request)
    {
        $customerId = $request->header('X-User-Id');
        $user = DB::table('users')->where('id', $customerId)->first();

        if (!Hash::check($request->old_password, $user->password_hash)) {
            return response()->json(['message' => 'Password lama Anda tidak sesuai.'], 400);
        }

        DB::table('users')->where('id', $customerId)->update([
            'password_hash' => Hash::make($request->new_password),
            'updated_at' => now(),
        ]);
        return response()->json(['status' => 200, 'message' => 'Password berhasil diperbarui!']);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $customerId = $request->header('X-User-Id');
        if (!$customerId) {
            return response()->json(['message' => 'User ID is missing'], 401);
        }

        DB::table('users')->where('id', $customerId)->update([
            'fcm_token' => $request->fcm_token,
            'updated_at' => now(),
        ]);

        return response()->json(['status' => 200, 'message' => 'FCM Token updated successfully']);
    }
}
