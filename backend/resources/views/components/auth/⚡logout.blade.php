<?php

use Livewire\Component;
use Illuminate\Support\Facades\Auth;

new class extends Component
{
    public function logout(): void
    {
        Auth::logout();
        session()->invalidate();
        session()->regenerateToken();
        $this->redirectRoute('login');
    }
};
?>

<button wire:click="logout" class="w-full text-left px-3 py-2 text-sm text-coffee-danger hover:bg-coffee-danger/10 rounded-lg flex items-center gap-2 cursor-pointer transition-all">
    <span class="text-base">🚪</span>
    <span>Keluar</span>
</button>