<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        if (!auth()->check()) {
            return $request->expectsJson() 
                ? response()->json(['message' => 'Unauthenticated.'], 401) 
                : redirect()->route('login');
        }

        $user = auth()->user();
        if (!in_array($user->role, $roles)) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Forbidden'], 403);
            }
            if ($user->role === 'admin') {
                return redirect()->route('admin.dashboard');
            } elseif ($user->role === 'pegawai') {
                return redirect()->route('pegawai.dashboard');
            }
            abort(403, 'Unauthorized action.');
        }

        return $next($request);
    }
}
