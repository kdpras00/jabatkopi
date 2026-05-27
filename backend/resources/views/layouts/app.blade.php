<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Jabat Kopi Backend' }}</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;600;800&display=swap" rel="stylesheet">

    <!-- Vite Styles and Scripts (Loads Tailwind CSS v4 and Client hot-reload script) -->
    @vite(['resources/css/app.css', 'resources/js/app.js'])

    @livewireStyles
</head>
<body class="font-sans antialiased">
    <div class="flex w-full min-h-screen" x-data="{ sidebarOpen: false }">
        <!-- Sidebar Backdrop (Mobile Only) -->
        @auth
            <div x-show="sidebarOpen" 
                 @click="sidebarOpen = false" 
                 class="fixed inset-0 bg-black/60 backdrop-blur-sm z-20 lg:hidden"
                 x-transition:enter="transition ease-out duration-300"
                 x-transition:enter-start="opacity-0"
                 x-transition:enter-end="opacity-100"
                 x-transition:leave="transition ease-in duration-200"
                 x-transition:leave-start="opacity-100"
                 x-transition:leave-end="opacity-0"
                 style="display: none;">
            </div>

            <!-- Sidebar -->
            <aside class="w-[280px] bg-coffee-panel backdrop-blur-md border-r border-coffee-border p-8 flex flex-col justify-between fixed h-screen z-30 transition-transform duration-300 ease-in-out lg:translate-x-0 lg:left-0"
                   :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'">
                
                <!-- Close Button (Mobile Only) -->
                <button @click="sidebarOpen = false" class="lg:hidden absolute top-6 right-6 text-coffee-muted hover:text-coffee-text focus:outline-none cursor-pointer p-1.5 hover:bg-white/5 rounded-lg border border-coffee-border/20 transition-all">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                </button>

                <div>
                    <a href="#" class="flex items-center gap-3 mb-12 no-underline text-coffee-text">
                        <img src="{{ asset('storage/images/logojabatkopi.png') }}" alt="Jabat Kopi Logo" class="w-8 h-8 object-contain rounded-lg">
                        <span class="text-lg font-extrabold tracking-wider bg-gradient-to-br from-coffee-text via-coffee-text to-coffee-primary bg-clip-text text-transparent">Jabat Kopi</span>
                    </a>
                    
                    <ul class="list-none flex flex-col gap-2 grow w-full">
                        @if(auth()->user()->role === 'admin')
                            <li class="nav-item">
                                <a href="{{ route('admin.dashboard') }}" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('admin.dashboard') && request('tab', 'overview') === 'overview' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
                                    <span>Dashboard</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="{{ route('admin.dashboard') }}?tab=tables" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('admin.dashboard') && request('tab') === 'tables' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path></svg>
                                    <span>Kelola Meja</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="{{ route('admin.dashboard') }}?tab=menus" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('admin.dashboard') && request('tab') === 'menus' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" d="M17 8h2a2 2 0 012 2v2a2 2 0 01-2 2h-2M2 8h15v8a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/><path stroke-linecap="round" stroke-linejoin="round" d="M6 1h0M10 1h0M14 1h0"/></svg>
                                    <span>Kelola Menu</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="{{ route('admin.dashboard') }}?tab=staff" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('admin.dashboard') && request('tab') === 'staff' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                    <span>Kelola Pegawai</span>
                                </a>
                            </li>
                        @endif
                        @if(auth()->user()->role === 'pegawai')
                            <li class="nav-item">
                                <a href="{{ route('pegawai.dashboard') }}" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('pegawai.dashboard') && (!request('tab') || request('tab') === 'overview') ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
                                    <span>Dashboard Pegawai</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="{{ route('pegawai.dashboard') }}?tab=orders" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('pegawai.dashboard') && request('tab') === 'orders' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                                    <span>Approve Orders</span>
                                </a>
                            </li>
                            <li class="nav-item">
                                <a href="{{ route('pegawai.dashboard') }}?tab=reservations" 
                                   class="flex items-center gap-3 py-3 px-4 rounded-lg font-medium border border-transparent transition-all {{ request()->routeIs('pegawai.dashboard') && request('tab') === 'reservations' ? 'bg-coffee-primary text-black font-semibold hover:bg-coffee-primary-hover hover:text-black' : 'text-coffee-muted hover:text-coffee-text hover:bg-coffee-primary/10 hover:border-coffee-primary/20' }}">
                                    <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                    <span>Approve Reservasi</span>
                                </a>
                            </li>
                        @endif
                    </ul>
                </div>
            </aside>
        @endauth

        <!-- Main Content -->
        <main class="grow min-h-screen {{ auth()->check() ? 'lg:ml-[280px] ml-0' : 'p-0 m-0' }}">
            @auth
                <!-- Top Header Bar -->
                <header class="h-20 border-b border-coffee-border bg-coffee-panel/30 backdrop-blur-md px-10 max-lg:px-6 flex items-center justify-between sticky top-0 z-20">
                    <div class="flex items-center gap-3">
                        <!-- Hamburger Button (Mobile Only) -->
                        <button @click="sidebarOpen = true" class="lg:hidden text-coffee-muted hover:text-coffee-text focus:outline-none p-2 border border-coffee-border/40 rounded-lg cursor-pointer hover:bg-white/5 transition-all">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                            </svg>
                        </button>

                        <!-- Active page/tab title -->
                        @if(auth()->user()->role === 'admin')
                            <h2 class="text-lg font-bold text-coffee-text font-outfit">
                                @if(request('tab') === 'tables')
                                    Kelola Meja
                                @elseif(request('tab') === 'menus')
                                    Kelola Menu
                                @elseif(request('tab') === 'staff')
                                    Kelola Pegawai
                                @else
                                    Dashboard Ringkasan
                                @endif
                            </h2>
                        @else
                            <h2 class="text-lg font-bold text-coffee-text font-outfit">
                                @if(request('tab') === 'orders')
                                    Approve Orders
                                @elseif(request('tab') === 'reservations')
                                    Approve Reservasi
                                @else
                                    Dashboard Pegawai
                                @endif
                            </h2>
                        @endif
                    </div>
                    
                    <!-- Profile dropdown -->
                    <div x-data="{ open: false }" class="relative">
                        <button @click="open = !open" class="flex items-center gap-3 focus:outline-none group cursor-pointer">
                            <div class="w-10 h-10 rounded-full bg-coffee-primary text-black flex items-center justify-center font-bold text-lg">
                                {{ strtoupper(substr(auth()->user()->name, 0, 1)) }}
                            </div>
                            <div class="flex flex-col items-start text-left max-sm:hidden">
                                <span class="text-sm font-semibold text-coffee-text group-hover:text-coffee-primary">{{ auth()->user()->name }}</span>
                                <span class="text-[10px] text-coffee-muted uppercase tracking-wider font-bold mt-0.5">{{ auth()->user()->role }}</span>
                            </div>
                        </button>
                        
                        <!-- Dropdown Menu -->
                        <div x-show="open" 
                             @click.outside="open = false"
                             x-transition:enter="transition ease-out duration-100"
                             x-transition:enter-start="transform opacity-0 scale-95"
                             x-transition:enter-end="transform opacity-100 scale-100"
                             x-transition:leave="transition ease-in duration-75"
                             x-transition:leave-start="transform opacity-100 scale-100"
                             x-transition:leave-end="transform opacity-0 scale-95"
                             class="absolute right-0 mt-3 w-56 bg-neutral-950 border border-coffee-border rounded-xl shadow-2xl py-2 z-30"
                             style="display: none;">
                            <div class="px-4 py-3 border-b border-coffee-border/40 text-xs">
                                <p class="font-semibold text-coffee-text">{{ auth()->user()->name }}</p>
                                <p class="text-coffee-muted mt-0.5 font-mono text-[10px]">{{ auth()->user()->email }}</p>
                            </div>
                            <div class="p-1.5">
                                @livewire('auth.logout')
                            </div>
                        </div>
                    </div>
                </header>
            @endauth

            <div class="{{ auth()->check() ? 'p-10 max-lg:p-6' : '' }}">
                {{ $slot }}
            </div>
        </main>
    </div>

    @livewireScripts
    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script>
        window.confirmDelete = (title, text, callback) => {
            Swal.fire({
                title: title || 'Apakah Anda yakin?',
                text: text || 'Tindakan ini tidak dapat dibatalkan!',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Ya, Hapus!',
                cancelButtonText: 'Batal',
                background: '#1a1210',
                color: '#f5ece6',
                confirmButtonColor: '#e06c75',
                cancelButtonColor: '#a69890',
                iconColor: '#e06c75',
                customClass: {
                    popup: 'border border-coffee-border/30 rounded-xl shadow-2xl p-6',
                    confirmButton: 'px-5 py-2.5 bg-coffee-danger hover:bg-coffee-danger/80 text-black font-bold text-sm rounded-lg shadow-lg mr-3 transition-all cursor-pointer',
                    cancelButton: 'px-5 py-2.5 bg-transparent border border-coffee-border text-coffee-text hover:bg-white/5 font-bold text-sm rounded-lg transition-all cursor-pointer'
                },
                buttonsStyling: false
            }).then((result) => {
                if (result.isConfirmed) {
                    callback();
                }
            });
        };

        const showToast = (text, type = 'success') => {
            const Toast = Swal.mixin({
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000,
                timerProgressBar: true,
                background: '#1a1210', // coffee-panel style
                color: '#f5ece6', // coffee-text
                iconColor: type === 'success' ? '#98c379' : '#e06c75',
                customClass: {
                    popup: 'border border-coffee-border/30 rounded-xl shadow-2xl'
                },
                didOpen: (toast) => {
                    toast.addEventListener('mouseenter', Swal.stopTimer)
                    toast.addEventListener('mouseleave', Swal.resumeTimer)
                }
            });
            Toast.fire({
                icon: type,
                title: text
            });
        };

        document.addEventListener('livewire:init', () => {
            Livewire.on('toast', (data) => {
                const payload = Array.isArray(data) ? data[0] : data;
                const text = payload.text || payload.message || '';
                const type = payload.type || 'success';
                showToast(text, type);
            });
            
            Livewire.on('alert', (data) => {
                const payload = Array.isArray(data) ? data[0] : data;
                Swal.fire({
                    icon: payload.type || 'success',
                    title: payload.title || '',
                    text: payload.text || payload.message || '',
                    background: '#1a1210',
                    color: '#f5ece6',
                    confirmButtonColor: '#d49a6a',
                    iconColor: payload.type === 'success' ? '#98c379' : '#e06c75',
                    customClass: {
                        popup: 'border border-coffee-border/30 rounded-xl shadow-2xl',
                        confirmButton: 'px-5 py-2.5 rounded-lg text-black font-bold text-sm bg-coffee-primary hover:bg-coffee-primary-hover shadow-lg transition-all cursor-pointer'
                    },
                    buttonsStyling: false
                });
            });
        });
    </script>
</body>
</html>
