<?php

use Livewire\Component;
use Livewire\Attributes\Url;
use Livewire\WithFileUploads;
use App\Models\User;
use App\Models\Table;
use App\Models\Menu;

new class extends Component
{
    use WithFileUploads;

    #[Url(as: 'tab')]
    public string $activeTab = 'overview';

    public bool $showForm = false;

    protected $listeners = [
        'echo:orders,OrderCreated' => '$refresh',
        'echo:reservations,ReservationCreated' => '$refresh',
    ];

    // Staff properties
    public string $staffId = '';
    public string $staffName = '';
    public string $staffUsername = '';
    public string $staffEmail = '';
    public string $staffPassword = '';
    public string $staffRole = 'pegawai';

    // Table properties
    public string $tableId = '';
    public string $tableQrRef = '';
    public string $tableStatus = 'available';
    public int $tableCapacity = 2;

    // Menu properties
    public string $menuId = '';
    public string $menuName = '';
    public string $menuCategory = 'coffee';
    public float $menuPrice = 0.0;
    public int $menuStock = 0;
    public bool $menuIsAvailable = true;
    public string $menuImageUrl = '';
    public $menuImageFile;

    // UI state
    public bool $isEditing = false;

    public function selectTab(string $tab): void
    {
        $this->activeTab = $tab;
        $this->resetForm();
    }

    public function openForm(): void
    {
        $this->isEditing = false;
        $this->showForm = true;
    }

    public function resetForm(): void
    {
        $this->isEditing = false;
        $this->showForm = false;
        
        // Reset staff
        $this->reset(['staffId', 'staffName', 'staffUsername', 'staffEmail', 'staffPassword', 'staffRole']);
        
        // Reset table
        $this->reset(['tableId', 'tableQrRef', 'tableStatus', 'tableCapacity']);

        // Reset menu
        $this->reset(['menuId', 'menuName', 'menuCategory', 'menuPrice', 'menuStock', 'menuIsAvailable', 'menuImageUrl', 'menuImageFile']);
    }

    // --- STAFF CRUD ---
    public function saveStaff(): void
    {
        $this->validate([
            'staffName' => 'required|string',
            'staffUsername' => 'required|string',
            'staffEmail' => 'required|email',
            'staffRole' => 'required|in:admin,pegawai',
            'staffPassword' => $this->isEditing ? 'nullable' : 'required',
        ]);

        if ($this->isEditing) {
            $user = User::find($this->staffId);
            $user->update([
                'name' => $this->staffName,
                'username' => $this->staffUsername,
                'email' => $this->staffEmail,
            ]);
            $user->syncRoles([$this->staffRole]);

            if ($this->staffPassword) {
                $user->update([
                    'password' => bcrypt($this->staffPassword)
                ]);
            }
            $this->dispatch('toast', text: 'Akun staff berhasil diperbarui.', type: 'success');
        } else {
            $user = User::create([
                'name' => $this->staffName,
                'username' => $this->staffUsername,
                'email' => $this->staffEmail,
                'password' => bcrypt($this->staffPassword),
            ]);
            $user->assignRole($this->staffRole);
            $this->dispatch('toast', text: 'Akun staff baru berhasil dibuat.', type: 'success');
        }

        $this->resetForm();
    }

    public function editStaff(int $id): void
    {
        $user = User::find($id);
        $this->staffId = $user->id;
        $this->staffName = $user->name;
        $this->staffUsername = $user->username;
        $this->staffEmail = $user->email;
        $this->staffRole = $user->getRoleNames()->first() ?? 'pegawai';
        
        $this->isEditing = true;
        $this->showForm = true;
    }

    public function deleteStaff(int $id): void
    {
        $user = User::find($id);
        if ($user) {
            $user->delete();
            $this->dispatch('toast', text: 'Akun staff berhasil dihapus.', type: 'success');
        }
    }

    // --- TABLE CRUD ---
    public function saveTable(): void
    {
        $this->validate([
            'tableQrRef' => 'required|string',
            'tableCapacity' => 'required|integer|min:1',
            'tableStatus' => 'required|string',
        ]);

        if ($this->isEditing) {
            Table::find($this->tableId)->update([
                'qr_code_ref' => $this->tableQrRef,
                'capacity' => $this->tableCapacity,
                'status' => $this->tableStatus,
            ]);
            $this->dispatch('toast', text: 'Data meja berhasil diperbarui.', type: 'success');
        } else {
            Table::create([
                'qr_code_ref' => $this->tableQrRef,
                'capacity' => $this->tableCapacity,
                'status' => $this->tableStatus,
            ]);
            $this->dispatch('toast', text: 'Meja baru berhasil ditambahkan.', type: 'success');
        }

        $this->resetForm();
    }

    public function editTable(int $id): void
    {
        $table = Table::find($id);
        $this->tableId = $table->id;
        $this->tableQrRef = $table->qr_code_ref;
        $this->tableCapacity = $table->capacity;
        $this->tableStatus = $table->status;
        
        $this->isEditing = true;
        $this->showForm = true;
    }

    public function deleteTable(int $id): void
    {
        Table::destroy($id);
        $this->dispatch('toast', text: 'Meja berhasil dihapus.', type: 'success');
    }

    // --- MENU CRUD ---
    public function saveMenu(): void
    {
        $this->validate([
            'menuName' => 'required|string',
            'menuCategory' => 'required|string',
            'menuPrice' => 'required|numeric|min:0',
            'menuStock' => 'required|integer|min:0',
            'menuImageFile' => 'nullable|image|max:2048',
            'menuImageUrl' => 'nullable|string',
        ]);

        $finalImageUrl = $this->menuImageUrl;

        if ($this->menuImageFile) {
            $path = $this->menuImageFile->store('menus', 'public');
            $finalImageUrl = asset('storage/' . $path);
        }

        if ($this->isEditing) {
            Menu::find($this->menuId)->update([
                'name' => $this->menuName,
                'category' => $this->menuCategory,
                'price' => $this->menuPrice,
                'stock' => $this->menuStock,
                'is_available' => $this->menuIsAvailable,
                'image_url' => $finalImageUrl,
            ]);
            $this->dispatch('toast', text: 'Item menu berhasil diperbarui.', type: 'success');
        } else {
            Menu::create([
                'name' => $this->menuName,
                'category' => $this->menuCategory,
                'price' => $this->menuPrice,
                'stock' => $this->menuStock,
                'is_available' => $this->menuIsAvailable,
                'image_url' => $finalImageUrl,
            ]);
            $this->dispatch('toast', text: 'Menu baru berhasil ditambahkan.', type: 'success');
        }

        $this->resetForm();
    }

    public function editMenu(int $id): void
    {
        $menu = Menu::find($id);
        $this->menuId = $menu->id;
        $this->menuName = $menu->name;
        $this->menuCategory = $menu->category;
        $this->menuPrice = $menu->price;
        $this->menuStock = $menu->stock;
        $this->menuIsAvailable = $menu->is_available;
        $this->menuImageUrl = $menu->image_url ?? '';
        
        $this->isEditing = true;
        $this->showForm = true;
    }

    public function deleteMenu(int $id): void
    {
        Menu::destroy($id);
        $this->dispatch('toast', text: 'Item menu berhasil dihapus.', type: 'success');
    }

    public function render()
    {
        $allUsers = User::with('roles')->get();
        $totalUsers = $allUsers->count();
        $totalAdmin = User::role('admin')->count();
        $totalPegawai = User::role('pegawai')->count();
        
        $staff = User::role(['admin', 'pegawai'])->get();
        
        $tables = Table::all();
        $menus = Menu::all();

        return view('pages.admin.dashboard', [
            'staff' => $staff,
            'totalUsers' => $totalUsers,
            'totalAdmin' => $totalAdmin,
            'totalPegawai' => $totalPegawai,
            'tables' => $tables,
            'menus' => $menus,
        ]);
    }
};
?>
<div>
    <!-- OVERVIEW TAB -->
    @if($activeTab === 'overview')
        <div>
            <div class="mb-8">
                <h1 class="text-3.5xl text-coffee-text font-extrabold tracking-tight">Dashboard Ringkasan</h1>
                <p class="text-coffee-muted text-sm mt-1">Kelola operasional dan administrasi sistem Jabat Kopi.</p>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-4 gap-6 mb-8 max-xl:grid-cols-2 max-sm:grid-cols-1">
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Total Pengguna</h3>
                        <div class="text-2xl font-bold text-coffee-text font-outfit">{{ $totalUsers }}</div>
                    </div>
                </div>
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Jumlah Meja</h3>
                        <div class="text-2xl font-bold text-coffee-text font-outfit">{{ $tables->count() }}</div>
                    </div>
                </div>
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Jumlah Item Menu</h3>
                        <div class="text-2xl font-bold text-coffee-text font-outfit">{{ $menus->count() }}</div>
                    </div>
                </div>
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Pendapatan Hari Ini</h3>
                        <div class="text-2xl font-bold text-coffee-primary font-outfit">Rp 1.425.000</div>
                    </div>
                </div>
            </div>

            <!-- Grid Layout -->
            <div class="grid grid-cols-3 gap-8 max-xl:grid-cols-1">
                <div class="col-span-2 bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg text-coffee-text font-semibold">Stok Rendah / Peringatan</h2>
                    </div>
                    <!-- Desktop Table View -->
                    <div class="hidden sm:block overflow-x-auto w-full">
                        <table class="w-full border-collapse text-left text-sm">
                            <thead>
                                <tr>
                                    <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Nama Menu</th>
                                    <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Kategori</th>
                                    <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Sisa Stok</th>
                                    <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Status Stok</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($menus->where('stock', '<', 10) as $lowMenu)
                                    <tr class="hover:bg-coffee-primary/3">
                                        <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-semibold">{{ $lowMenu->name }}</td>
                                        <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text capitalize">{{ $lowMenu->category }}</td>
                                        <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-danger font-bold">{{ $lowMenu->stock }}</td>
                                        <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                            @if($lowMenu->stock == 0)
                                                <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Habis</span>
                                            @else
                                                <span class="bg-amber-500 text-black px-2 py-1 rounded text-xs font-semibold">Hampir Habis</span>
                                            @endif
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="4" class="text-center text-coffee-muted py-8">Stok semua menu aman dan mencukupi.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <!-- Mobile Card View -->
                    <div class="block sm:hidden space-y-4">
                        @forelse($menus->where('stock', '<', 10) as $lowMenu)
                            <div class="bg-black/30 border border-coffee-border/40 rounded-xl p-4 flex flex-col gap-2">
                                <div class="flex justify-between items-center">
                                    <span class="font-semibold text-coffee-text text-sm">{{ $lowMenu->name }}</span>
                                    @if($lowMenu->stock == 0)
                                        <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Habis</span>
                                    @else
                                        <span class="bg-amber-500 text-black px-2 py-0.5 rounded text-[10px] font-semibold">Hampir Habis</span>
                                    @endif
                                </div>
                                <div class="flex justify-between text-xs text-coffee-muted">
                                    <span>Kategori: <strong class="text-coffee-text capitalize">{{ $lowMenu->category }}</strong></span>
                                    <span>Sisa Stok: <strong class="text-coffee-danger font-bold">{{ $lowMenu->stock }}</strong></span>
                                </div>
                            </div>
                        @empty
                            <div class="text-center text-coffee-muted py-4 text-sm">Stok semua menu aman dan mencukupi.</div>
                        @endforelse
                    </div>
                </div>

                <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg text-coffee-text font-semibold">Ringkasan Sistem</h2>
                    </div>
                    <div class="flex flex-col gap-4 mt-4">
                        <div class="flex justify-between pb-3 border-b border-coffee-border/50 text-sm">
                            <span class="text-coffee-muted">Akun Admin:</span>
                            <span class="font-semibold text-coffee-text">{{ $totalAdmin }}</span>
                        </div>
                        <div class="flex justify-between pb-3 border-b border-coffee-border/50 text-sm">
                            <span class="text-coffee-muted">Akun Staff:</span>
                            <span class="font-semibold text-coffee-text">{{ $totalPegawai }}</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-coffee-muted">Total Meja Terisi:</span>
                            <span class="font-semibold text-coffee-success">{{ $tables->where('status', 'occupied')->count() }} Meja</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    @endif

    <!-- KELOLA MEJA TAB -->
    @if($activeTab === 'tables')
        @if(!$showForm)
            <!-- List View -->
            <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl mb-8">
                <div class="flex justify-end mb-6">
                    <button wire:click="openForm" class="py-2.5 px-5 bg-coffee-primary text-black font-bold text-sm rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                        Tambah Meja
                    </button>
                </div>
                <!-- Desktop Table View -->
                <div class="hidden md:block overflow-x-auto w-full">
                    <table class="w-full border-collapse text-left text-sm">
                        <thead>
                            <tr>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">ID</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Nomor Meja</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Kapasitas</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Status</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($tables as $table)
                                <tr class="hover:bg-coffee-primary/3">
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">{{ $table->id }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-mono">{{ $table->qr_code_ref }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">{{ $table->capacity }} Orang</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                        @if($table->status === 'available')
                                            <span class="bg-coffee-success text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Tersedia</span>
                                        @elseif($table->status === 'occupied')
                                            <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Terisi</span>
                                        @else
                                            <span class="bg-amber-500 text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">{{ $table->status }}</span>
                                        @endif
                                    </td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text text-right">
                                        <button wire:click="editTable({{ $table->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs mr-1.5 cursor-pointer">
                                            Ubah
                                        </button>
                                        <button onclick="confirmDelete('Hapus Meja?', 'Apakah Anda yakin ingin menghapus meja ini?', () => @this.deleteTable({{ $table->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer">
                                            Hapus
                                        </button>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="text-center text-coffee-muted py-8">Belum ada meja terdaftar.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <!-- Mobile Card View -->
                <div class="block md:hidden space-y-4">
                    @forelse($tables as $table)
                        <div class="bg-black/40 border border-coffee-border/60 rounded-xl p-4 flex flex-col gap-3 shadow-md">
                             <div class="flex justify-between items-center">
                                <span class="text-xs text-coffee-muted font-bold">ID: #{{ $table->id }}</span>
                                @if($table->status === 'available')
                                    <span class="bg-coffee-success text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Tersedia</span>
                                @elseif($table->status === 'occupied')
                                    <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Terisi</span>
                                @else
                                    <span class="bg-amber-500 text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">{{ $table->status }}</span>
                                @endif
                            </div>
                            
                            <div class="flex justify-between items-center text-sm border-t border-b border-coffee-border/20 py-2">
                                <div>
                                    <span class="block text-xxs text-coffee-muted uppercase">Nomor Meja</span>
                                    <span class="font-semibold text-coffee-text font-mono">{{ $table->qr_code_ref }}</span>
                                </div>
                                <div class="text-right">
                                    <span class="block text-xxs text-coffee-muted uppercase">Kapasitas</span>
                                    <span class="font-semibold text-coffee-text">{{ $table->capacity }} Orang</span>
                                </div>
                            </div>
                            
                            <div class="flex justify-end gap-2 mt-1">
                                <button wire:click="editTable({{ $table->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs cursor-pointer">
                                    Ubah
                                </button>
                                <button onclick="confirmDelete('Hapus Meja?', 'Apakah Anda yakin ingin menghapus meja ini?', () => @this.deleteTable({{ $table->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer">
                                    Hapus
                                </button>
                            </div>
                        </div>
                    @empty
                        <div class="text-center text-coffee-muted py-8 text-sm">Belum ada meja terdaftar.</div>
                    @endforelse
                </div>
            </div>
        @else
            <!-- Form View (Centered & Separate) -->
            <div class="flex justify-center w-full">
                <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl w-full max-w-[600px]">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg text-coffee-text font-semibold">{{ $isEditing ? 'Ubah Meja' : 'Tambah Meja Baru' }}</h2>
                    </div>
                    <form wire:submit.prevent="saveTable">
                        <div class="mb-5">
                            <label for="tableQrRef" class="block mb-2 text-sm text-coffee-muted font-medium">Nomor Meja</label>
                            <input type="text" id="tableQrRef" wire:model="tableQrRef" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="MEJA-01" required>
                            @error('tableQrRef') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="tableCapacity" class="block mb-2 text-sm text-coffee-muted font-medium">Kapasitas (Orang)</label>
                            <input type="number" id="tableCapacity" wire:model="tableCapacity" min="1" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" required>
                            @error('tableCapacity') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="tableStatus" class="block mb-2 text-sm text-coffee-muted font-medium">Status Meja</label>
                            <select id="tableStatus" wire:model="tableStatus" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all">
                                <option value="available">Tersedia</option>
                                <option value="occupied">Terisi</option>
                            </select>
                            @error('tableStatus') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="flex gap-4 mt-8">
                            <button type="submit" class="flex-1 py-3 px-6 bg-coffee-primary text-black font-bold text-base rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                                {{ $isEditing ? 'Perbarui' : 'Simpan' }}
                            </button>
                            <button type="button" wire:click="resetForm" class="py-3 px-6 bg-transparent border border-coffee-border text-coffee-muted font-semibold text-base rounded-lg cursor-pointer hover:bg-white/5 transition-all">
                                Batal
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        @endif
    @endif

    <!-- KELOLA MENU TAB -->
    @if($activeTab === 'menus')
        @if(!$showForm)
            <!-- List View -->
            <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl mb-8">
                <div class="flex justify-end mb-6">
                    <button wire:click="openForm" class="py-2.5 px-5 bg-coffee-primary text-black font-bold text-sm rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                        Tambah Menu
                    </button>
                </div>
                <!-- Desktop Table View -->
                <div class="hidden md:block overflow-x-auto w-full">
                    <table class="w-full border-collapse text-left text-sm">
                        <thead>
                            <tr>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Gambar</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Nama</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Kategori</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Harga</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Stok</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Status</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($menus as $menu)
                                <tr class="hover:bg-coffee-primary/3">
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text align-middle">
                                        @if($menu->image_url)
                                            <img src="{{ $menu->image_url }}" alt="{{ $menu->name }}" class="w-12 h-12 object-cover rounded-lg border border-coffee-border shadow-md">
                                        @else
                                            <div class="w-12 h-12 rounded-lg bg-coffee-primary/5 border border-dashed border-coffee-border flex items-center justify-center text-coffee-muted text-[10px] font-medium">
                                                No Img
                                            </div>
                                        @endif
                                    </td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-semibold align-middle">{{ $menu->name }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text capitalize align-middle">{{ $menu->category }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-primary font-bold align-middle">Rp {{ number_format($menu->price, 0, ',', '.') }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text align-middle">{{ $menu->stock }} pcs</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text align-middle">
                                        @if($menu->is_available && $menu->stock > 0)
                                            <span class="bg-coffee-success text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Tersedia</span>
                                        @else
                                            <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Habis</span>
                                        @endif
                                    </td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text text-right align-middle">
                                        <button wire:click="editMenu({{ $menu->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs mr-1.5 cursor-pointer">
                                            Ubah
                                        </button>
                                        <button onclick="confirmDelete('Hapus Item Menu?', 'Apakah Anda yakin ingin menghapus item menu ini?', () => @this.deleteMenu({{ $menu->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer">
                                            Hapus
                                        </button>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center text-coffee-muted py-8">Belum ada item menu terdaftar.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <!-- Mobile Card View -->
                <div class="block md:hidden space-y-4">
                    @forelse($menus as $menu)
                        <div class="bg-black/40 border border-coffee-border/60 rounded-xl p-4 flex flex-col gap-3 shadow-md">
                            <div class="flex gap-4 items-center">
                                <div class="w-16 h-16 rounded-lg overflow-hidden border border-coffee-border shrink-0">
                                    @if($menu->image_url)
                                        <img src="{{ $menu->image_url }}" alt="{{ $menu->name }}" class="w-full h-full object-cover">
                                    @else
                                        <div class="w-full h-full bg-coffee-primary/5 flex items-center justify-center text-coffee-muted text-[10px] font-medium">No Img</div>
                                    @endif
                                </div>
                                <div class="grow min-w-0">
                                    <div class="flex justify-between items-start gap-2">
                                        <h4 class="font-bold text-coffee-text text-base truncate">{{ $menu->name }}</h4>
                                        @if($menu->is_available && $menu->stock > 0)
                                            <span class="bg-coffee-success text-black px-1.5 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider shrink-0">Ada</span>
                                        @else
                                            <span class="bg-coffee-danger text-black px-1.5 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider shrink-0">Habis</span>
                                        @endif
                                    </div>
                                    <span class="text-xs text-coffee-muted capitalize">{{ $menu->category }}</span>
                                    <div class="text-coffee-primary font-bold text-sm mt-1">Rp {{ number_format($menu->price, 0, ',', '.') }}</div>
                                </div>
                             </div>
                             
                             <div class="flex justify-between items-center text-xs border-t border-coffee-border/20 pt-3 mt-1">
                                <span class="text-coffee-muted">Stok: <strong class="text-coffee-text">{{ $menu->stock }} pcs</strong></span>
                                <div class="flex gap-2">
                                    <button wire:click="editMenu({{ $menu->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs cursor-pointer">
                                        Ubah
                                    </button>
                                    <button onclick="confirmDelete('Hapus Item Menu?', 'Apakah Anda yakin ingin menghapus item menu ini?', () => @this.deleteMenu({{ $menu->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer">
                                        Hapus
                                    </button>
                                </div>
                             </div>
                        </div>
                    @empty
                        <div class="text-center text-coffee-muted py-8 text-sm">Belum ada item menu terdaftar.</div>
                    @endforelse
                </div>
            </div>
        @else
            <!-- Form View (Centered & Separate) -->
            <div class="flex justify-center w-full">
                <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl w-full max-w-[600px]">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg text-coffee-text font-semibold">{{ $isEditing ? 'Ubah Item Menu' : 'Tambah Menu Baru' }}</h2>
                    </div>
                    <form wire:submit.prevent="saveMenu">
                        <div class="mb-5">
                            <label for="menuName" class="block mb-2 text-sm text-coffee-muted font-medium">Nama Menu</label>
                            <input type="text" id="menuName" wire:model="menuName" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="Cappuccino" required>
                            @error('menuName') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="menuCategory" class="block mb-2 text-sm text-coffee-muted font-medium">Kategori</label>
                            <select id="menuCategory" wire:model="menuCategory" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all">
                                <option value="coffee">Coffee</option>
                                <option value="non-coffee">Non-Coffee</option>
                                <option value="food">Food</option>
                                <option value="dessert">Dessert</option>
                            </select>
                            @error('menuCategory') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="menuPrice" class="block mb-2 text-sm text-coffee-muted font-medium">Harga (Rp)</label>
                            <input type="number" id="menuPrice" wire:model="menuPrice" min="0" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="30000" required>
                            @error('menuPrice') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="menuStock" class="block mb-2 text-sm text-coffee-muted font-medium">Stok Masuk</label>
                            <input type="number" id="menuStock" wire:model="menuStock" min="0" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="50" required>
                            @error('menuStock') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="flex items-center gap-2 mb-5">
                            <input type="checkbox" id="menuIsAvailable" wire:model="menuIsAvailable" class="accent-coffee-primary cursor-pointer w-4 h-4">
                            <label for="menuIsAvailable" class="text-coffee-text text-sm cursor-pointer select-none">Item Aktif / Tersedia</label>
                        </div>

                        <div class="mt-6 border-t border-coffee-border pt-6">
                            <label class="block mb-2 text-sm text-coffee-primary font-bold">Gambar Menu</label>
                            
                            <!-- Preview Section -->
                            <div class="flex gap-5 items-start mb-5 max-sm:flex-col">
                                <div class="w-[100px] h-[100px] rounded-xl overflow-hidden border border-coffee-border bg-coffee-primary/3 flex items-center justify-center shrink-0 relative shadow-lg">
                                    @if($menuImageFile)
                                        <img src="{{ $menuImageFile->temporaryUrl() }}" class="w-full h-full object-cover">
                                    @elseif($menuImageUrl)
                                        <img src="{{ $menuImageUrl }}" class="w-full h-full object-cover" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                        <div class="hidden w-full h-full items-center justify-center text-coffee-muted text-xs">Link Error</div>
                                    @else
                                        <div class="flex flex-col items-center justify-center text-center p-2 text-coffee-muted text-xs">
                                            Pratinjau
                                        </div>
                                    @endif
                                    
                                    <!-- Livewire Loading Spinner -->
                                    <div wire:loading wire:target="menuImageFile" class="absolute inset-0 bg-neutral-900/90 flex items-center justify-center text-xs text-coffee-primary font-semibold">
                                        Mengunggah...
                                    </div>
                                </div>
                                
                                <div class="grow flex flex-col gap-2">
                                    <span class="text-xs text-coffee-muted leading-relaxed">
                                        Pilih foto produk menu Anda. Format yang didukung: JPG, PNG, WEBP (Maksimal 2 MB).
                                    </span>
                                    <!-- Styled Custom File Input Button -->
                                    <div class="relative inline-block w-full">
                                        <input type="file" id="menuImageFile" wire:model="menuImageFile" accept="image/*" class="absolute left-0 top-0 opacity-0 w-full h-full cursor-pointer">
                                        <div class="py-2.5 px-4 bg-coffee-primary/10 border border-dashed border-coffee-primary text-coffee-primary rounded-lg text-sm font-semibold text-center cursor-pointer hover:bg-coffee-primary/20 transition-all">
                                            Upload File Gambar
                                        </div>
                                    </div>
                                    @error('menuImageFile') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                                </div>
                            </div>
                            
                            <!-- Or Link Input -->
                            <div class="flex items-center my-4 gap-3">
                                <div class="grow h-[1px] bg-coffee-border"></div>
                                <span class="text-xxs text-coffee-muted uppercase tracking-wider font-bold">Atau Gunakan Link URL</span>
                                <div class="grow h-[1px] bg-coffee-border"></div>
                            </div>
                            
                            <div class="mb-5">
                                <label for="menuImageUrl" class="block mb-2 text-xs text-coffee-muted font-medium">Tautkan URL Gambar Eksternal</label>
                                <input type="url" id="menuImageUrl" wire:model.live.debounce.500ms="menuImageUrl" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="https://example.com/kopi.jpg" {{ $menuImageFile ? 'disabled style=opacity:0.5;cursor:not-allowed;' : '' }}>
                                @error('menuImageUrl') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="flex gap-4 mt-8">
                            <button type="submit" class="flex-1 py-3 px-6 bg-coffee-primary text-black font-bold text-base rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                                {{ $isEditing ? 'Perbarui' : 'Simpan' }}
                            </button>
                            <button type="button" wire:click="resetForm" class="py-3 px-6 bg-transparent border border-coffee-border text-coffee-muted font-semibold text-base rounded-lg cursor-pointer hover:bg-white/5 transition-all">
                                Batal
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        @endif
    @endif

    <!-- KELOLA PEGAWAI TAB -->
    @if($activeTab === 'staff')
        @if(!$showForm)
            <!-- List View -->
            <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl mb-8">
                <div class="flex justify-end mb-6">
                    <button wire:click="openForm" class="py-2.5 px-5 bg-coffee-primary text-black font-bold text-sm rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                        Tambah Pegawai
                    </button>
                </div>
                <!-- Desktop Table View -->
                <div class="hidden md:block overflow-x-auto w-full">
                    <table class="w-full border-collapse text-left text-sm">
                        <thead>
                            <tr>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Nama Lengkap</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Username</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Email</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Role</th>
                                <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($staff as $user)
                                <tr class="hover:bg-coffee-primary/3">
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-semibold">{{ $user->name }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">{{ $user->username }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">{{ $user->email }}</td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                        @if($user->hasRole('admin'))
                                            <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Admin</span>
                                        @else
                                            <span class="bg-amber-500 text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Pegawai</span>
                                        @endif
                                    </td>
                                    <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text text-right">
                                        <button wire:click="editStaff({{ $user->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs mr-1.5 cursor-pointer">
                                            Ubah
                                        </button>
                                        <button onclick="confirmDelete('Hapus Akun Pegawai?', 'Apakah Anda yakin ingin menghapus akun staff ini?', () => @this.deleteStaff({{ $user->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer" {{ $user->id === auth()->user()->id ? 'disabled style=opacity:0.4;cursor:default;' : '' }}>
                                            Hapus
                                        </button>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="text-center text-coffee-muted py-8">Belum ada pegawai terdaftar.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <!-- Mobile Card View -->
                <div class="block md:hidden space-y-4">
                    @forelse($staff as $user)
                        <div class="bg-black/40 border border-coffee-border/60 rounded-xl p-4 flex flex-col gap-2 shadow-md">
                            <div class="flex justify-between items-center">
                                <h4 class="font-bold text-coffee-text text-base">{{ $user->name }}</h4>
                                 @if($user->hasRole('admin'))
                                    <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Admin</span>
                                 @else
                                    <span class="bg-amber-500 text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Pegawai</span>
                                 @endif
                            </div>
                            
                            <div class="text-xs text-coffee-muted space-y-1.5 py-2 border-t border-b border-coffee-border/20 my-1">
                                <div class="flex justify-between"><span class="uppercase text-xxs">Username:</span><span class="font-semibold text-coffee-text">{{ $user->username }}</span></div>
                                <div class="flex justify-between"><span class="uppercase text-xxs">Email:</span><span class="font-semibold text-coffee-text">{{ $user->email }}</span></div>
                            </div>
                            
                            <div class="flex justify-end gap-2 mt-1">
                                <button wire:click="editStaff({{ $user->id }})" class="py-1.5 px-3 bg-amber-500 text-black rounded font-bold hover:bg-amber-600 transition-all text-xs cursor-pointer">
                                    Ubah
                                </button>
                                <button onclick="confirmDelete('Hapus Akun Pegawai?', 'Apakah Anda yakin ingin menghapus akun staff ini?', () => @this.deleteStaff({{ $user->id }}))" class="py-1.5 px-3 bg-red-600 text-white rounded font-bold hover:bg-red-700 transition-all text-xs cursor-pointer" {{ $user->id === auth()->user()->id ? 'disabled style=opacity:0.4;cursor:default;' : '' }}>
                                    Hapus
                                </button>
                            </div>
                        </div>
                    @empty
                        <div class="text-center text-coffee-muted py-8 text-sm">Belum ada pegawai terdaftar.</div>
                    @endforelse
                </div>
            </div>
        @else
            <!-- Form View (Centered & Separate) -->
            <div class="flex justify-center w-full">
                <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl w-full max-w-[600px]">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg text-coffee-text font-semibold">{{ $isEditing ? 'Ubah Akun Pegawai' : 'Buat Akun Pegawai Baru' }}</h2>
                    </div>
                    <form wire:submit.prevent="saveStaff">
                        <div class="mb-5">
                            <label for="staffName" class="block mb-2 text-sm text-coffee-muted font-medium">Nama Lengkap</label>
                            <input type="text" id="staffName" wire:model="staffName" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="Budi Santoso" required>
                            @error('staffName') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="staffUsername" class="block mb-2 text-sm text-coffee-muted font-medium">Username</label>
                            <input type="text" id="staffUsername" wire:model="staffUsername" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="budisantoso" required>
                            @error('staffUsername') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="staffEmail" class="block mb-2 text-sm text-coffee-muted font-medium">Email</label>
                            <input type="email" id="staffEmail" wire:model="staffEmail" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="budi@jabatkopi.com" required>
                            @error('staffEmail') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="staffRole" class="block mb-2 text-sm text-coffee-muted font-medium">Peran (Role)</label>
                            <select id="staffRole" wire:model="staffRole" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all">
                                <option value="pegawai">Pegawai / Barista</option>
                                <option value="admin">Admin</option>
                            </select>
                            @error('staffRole') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="mb-5">
                            <label for="staffPassword" class="block mb-2 text-sm text-coffee-muted font-medium">Password {{ $isEditing ? '(Kosongkan jika tidak diubah)' : '' }}</label>
                            <input type="password" id="staffPassword" wire:model="staffPassword" class="w-full py-3 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-base focus:outline-none focus:border-coffee-primary focus:shadow-[0_0_10px_var(--color-coffee-primary-glow)] transition-all" placeholder="••••••••" {{ $isEditing ? '' : 'required' }}>
                            @error('staffPassword') <span class="text-coffee-danger text-xs mt-1 block">{{ $message }}</span> @enderror
                        </div>

                        <div class="flex gap-4 mt-8">
                            <button type="submit" class="flex-1 py-3 px-6 bg-coffee-primary text-black font-bold text-base rounded-lg shadow-md hover:bg-coffee-primary-hover cursor-pointer transition-all">
                                {{ $isEditing ? 'Perbarui' : 'Simpan' }}
                            </button>
                            <button type="button" wire:click="resetForm" class="py-3 px-6 bg-transparent border border-coffee-border text-coffee-muted font-semibold text-base rounded-lg cursor-pointer hover:bg-white/5 transition-all">
                                Batal
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        @endif
    @endif
</div>
