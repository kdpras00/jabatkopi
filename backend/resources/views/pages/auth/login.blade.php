<?php

use Livewire\Component;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

new class extends Component
{
    public string $email = '';
    public string $password = '';
    public bool $remember = false;

    protected array $rules = [
        'email' => 'required|email',
        'password' => 'required',
    ];

    public function login(): void
    {
        $this->validate();

        if (Auth::attempt(['email' => $this->email, 'password' => $this->password], $this->remember)) {
            session()->regenerate();

            $user = Auth::user();
            if ($user->role === 'admin') {
                $this->redirectRoute('admin.dashboard');
            } elseif ($user->role === 'pegawai') {
                $this->redirectRoute('pegawai.dashboard');
            } else {
                Auth::logout();
                throw ValidationException::withMessages([
                    'email' => 'Role tidak dikenali.',
                ]);
            }
            return;
        }

        throw ValidationException::withMessages([
            'email' => 'Email atau password yang Anda masukkan salah.',
        ]);
    }
};
?>

<div class="flex items-center justify-center w-screen min-h-screen p-4">
    <div class="w-full max-w-[440px] p-10 bg-coffee-panel backdrop-blur-2xl border border-coffee-border rounded-2xl shadow-2xl">
        <div class="text-center mb-8">
            <h1 class="text-4xl font-extrabold text-coffee-primary tracking-wider">Jabat Kopi</h1>
            <p class="text-coffee-muted text-sm mt-2">Masuk ke sistem backend staff & admin</p>
        </div>

        <form wire:submit="login">
            @error('email')
                <div class="p-3.5 bg-coffee-danger/15 text-coffee-danger border border-coffee-danger/30 rounded-lg text-sm font-medium mb-6">
                    {{ $message }}
                </div>
            @enderror
            @error('password')
                <div class="p-3.5 bg-coffee-danger/15 text-coffee-danger border border-coffee-danger/30 rounded-lg text-sm font-medium mb-6">
                    {{ $message }}
                </div>
            @enderror

            <div class="mb-5">
                <label for="email" class="block mb-2 text-sm text-coffee-muted font-medium">Alamat Email</label>
                <input type="email" id="email" wire:model="email" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="name@jabatkopi.com" autocomplete="email" required autofocus>
            </div>

            <div class="mb-6" x-data="{ show: false }">
                <label for="password" class="block mb-2 text-sm text-coffee-muted font-medium">Password</label>
                <div class="relative">
                    <input :type="show ? 'text' : 'password'" id="password" wire:model="password" class="w-full py-3 px-4 pr-12 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="••••••••" required>
                    <button type="button" @click="show = !show" class="absolute right-4 top-1/2 -translate-y-1/2 text-coffee-muted hover:text-coffee-primary transition-colors focus:outline-none">
                        <svg x-show="!show" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        <svg x-show="show" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5" style="display: none;">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                        </svg>
                    </button>
                </div>
            </div>

            <div class="flex items-center gap-2 mb-8">
                <input type="checkbox" id="remember" wire:model="remember" class="accent-coffee-primary cursor-pointer w-4 h-4">
                <label for="remember" class="text-coffee-muted text-sm cursor-pointer select-none">Ingat saya di perangkat ini</label>
            </div>

            <button type="submit" class="py-3 px-6 bg-coffee-primary text-black font-bold text-base rounded-lg shadow-[0_4px_15px_rgba(212,154,106,0.2)] hover:bg-coffee-primary-hover hover:-translate-y-0.5 hover:shadow-[0_6px_20px_var(--color-coffee-primary-glow)] active:translate-y-0 cursor-pointer text-center block w-full transition-all">
                Masuk Sekarang
            </button>
        </form>
    </div>
</div>
