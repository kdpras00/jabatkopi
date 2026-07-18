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

        $user = \App\Models\User::where('email', $request->email)->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau password salah'], 401);
        }
        $token = $user->createToken('auth_token')->plainTextToken;
        return response()->json([
            'status' => 200,
            'message' => 'Berhasil masuk!',
            'data' => [
                'id' => $user->id,
                'token' => $token,
                'role' => $user->getRoleNames()->first() ?? 'customer',
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
            'password' => Hash::make($request->password),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $user = \App\Models\User::where('email', $request->email)->first();
        if ($user) {
            $user->assignRole('customer');
        }
        return response()->json(['status' => 201, 'message' => 'Pendaftaran berhasil!']);
    }

    public function profile(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);
        $user = \App\Models\User::find($customerId);
        return response()->json([
            'status' => 200,
            'data' => [
                'id' => $user->id,
                'name' => $user->name ?? '',
                'username' => $user->username ?? '',
                'email' => $user->email ?? '',
                'image_url' => $user->image_url ?? '',
                'role' => $user->getRoleNames()->first() ?? 'customer',
            ]
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = \App\Models\User::find(auth()->id());

        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users,username,'.$user->id,
            'email' => 'required|string|email|max:255|unique:users,email,'.$user->id,
        ]);

        $updateData = [
            'name' => $request->name,
            'username' => $request->username,
            'email' => $request->email,
        ];

        if ($request->has('image_url')) {
            $updateData['image_url'] = $request->image_url;
        }

        $user->update($updateData);

        return response()->json(['status' => 200, 'message' => 'Profil berhasil diperbarui!']);
    }

    public function updatePassword(Request $request)
    {
        $customerId = auth()->id();
        if (!$customerId) return response()->json(['message' => 'Unauthorized'], 401);
        $user = \App\Models\User::find($customerId);

        $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ], [
            'new_password.min' => 'Password baru minimal 8 karakter.',
            'new_password.confirmed' => 'Konfirmasi password baru tidak cocok.',
        ]);

        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json(['message' => 'Password lama Anda tidak sesuai.'], 400);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);
        return response()->json(['status' => 200, 'message' => 'Password berhasil diperbarui!']);
    }

}
