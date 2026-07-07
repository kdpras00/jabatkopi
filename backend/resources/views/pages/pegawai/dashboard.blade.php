<?php

use Livewire\Component;
use Livewire\Attributes\Url;
use App\Models\Order;
use App\Models\Reservation;
use App\Models\Table;
use App\Models\Menu;
use Illuminate\Support\Facades\DB;

new class extends Component
{
    #[Url(as: 'tab')]
    public string $activeTab = 'overview';

    // Filters
    public string $orderFilter = 'all';
    public string $reservationFilter = 'all';
    public string $reservationSearch = '';

    protected $listeners = [
        'echo:orders,OrderCreated' => '$refresh',
        'echo:reservations,ReservationCreated' => '$refresh',
    ];

    // Cancel Modal state
    public bool $showCancelModal = false;
    public int $cancelReservationId = 0;
    public string $cancelReasonInput = '';

    public function selectTab(string $tab): void
    {
        $this->activeTab = $tab;
    }

    // --- ORDER ACTIONS ---
    public function updateOrderStatus(int $id, string $status): void
    {
        $order = Order::find($id);
        if ($order) {
            $oldStatus = $order->status;
            
            // Validasi: Pastikan meja sudah dipilih sebelum memproses pesanan
            if ($status !== 'cancelled' && empty($order->table_id)) {
                $this->dispatch('toast', text: "Gagal: Anda harus memilih nomor meja terlebih dahulu sebelum mengubah status pesanan.", type: 'error');
                return;
            }

            // Validasi transisi status (Linear/Sekuensial)
            $allowedTransitions = [
                'pending' => ['processing', 'cancelled'],
                'processing' => ['preparing', 'cancelled'],
                'preparing' => ['ready', 'cancelled'],
                'ready' => ['completed'],
            ];

            if ($oldStatus !== $status) {
                if (!isset($allowedTransitions[$oldStatus]) || !in_array($status, $allowedTransitions[$oldStatus])) {
                    $this->dispatch('toast', text: "Transisi status dari " . strtoupper($oldStatus) . " ke " . strtoupper($status) . " tidak diperbolehkan.", type: 'error');
                    return;
                }
            }

            $order->update([
                'status' => $status,
                'staff_name' => auth()->user() ? auth()->user()->username : 'SISTEM',
            ]);
            
            if ($oldStatus !== 'cancelled' && $status === 'cancelled') {
                // ponytail: one bulk UPDATE instead of N Menu::find() calls
                DB::table('menus')
                    ->joinSub(
                        DB::table('order_items')->where('order_id', $id)->select('menu_id', 'qty'),
                        'oi', 'oi.menu_id', '=', 'menus.id'
                    )
                    ->update(['menus.stock' => DB::raw('menus.stock + oi.qty')]);
            }

            // Note: Jangan ubah status meja atau reservasi saat pesanan selesai disajikan (completed).
            // Meja/reservasi hanya boleh dibebaskan melalui tombol manual agar meja tetap occupied selama makan.

            $this->dispatch('toast', text: "Status Pesanan #{$id} diperbarui menjadi: " . strtoupper($status), type: 'success');
        }
    }

    public function assignTable(int $orderId, int $tableId): void
    {
        $order = Order::find($orderId);
        $table = Table::find($tableId);
        if ($order && $table) {
            $order->update(['table_id' => $tableId]);
            if ($table->status !== 'occupied') {
                $table->update(['status' => 'occupied']);
            }
            $this->dispatch('toast', text: "Meja {$table->qr_code_ref} berhasil dialokasikan untuk Pesanan #{$orderId}.", type: 'success');
        }
    }

    public function freeTable(int $orderId): void
    {
        $order = Order::find($orderId);
        if ($order && $order->table_id) {
            $table = Table::find($order->table_id);
            if ($table) {
                $table->update(['status' => 'available']);
            }
            $order->update(['table_id' => null]);
            $this->dispatch('toast', text: "Meja berhasil dibebaskan dari Pesanan #{$orderId}.", type: 'success');
        }
    }
    // --- RESERVATION ACTIONS ---
    public function assignReservationTable(int $reservationId, int $tableId): void
    {
        $reservation = Reservation::find($reservationId);
        $table = Table::find($tableId);
        if ($reservation && $table) {
            if ($table->status === 'available') {
                $reservation->update(['table_id' => $tableId]);
                $table->update(['status' => 'occupied']);
                $this->dispatch('toast', text: "Meja {$table->qr_code_ref} dialokasikan ke Booking JK-RES-{$reservationId}.", type: 'success');
            } else {
                $this->dispatch('toast', text: "Meja {$table->qr_code_ref} sedang tidak tersedia.", type: 'error');
            }
        }
    }

    public function freeReservationTable(int $reservationId): void
    {
        $reservation = Reservation::find($reservationId);
        if ($reservation && $reservation->table_id) {
            $table = Table::find($reservation->table_id);
            if ($table) {
                $table->update(['status' => 'available']);
            }
            $reservation->update(['table_id' => null]);
            $this->dispatch('toast', text: "Meja dibebaskan dari Booking JK-RES-{$reservationId}.", type: 'success');
        }
    }

    public function confirmArrival(int $id): void
    {
        $reservation = Reservation::find($id);
        if ($reservation) {
            if (!$reservation->table_id) {
                $this->dispatch('toast', text: "Gagal: Tentukan nomor meja terlebih dahulu sebelum konfirmasi Tiba.", type: 'error');
                return;
            }
            $now = now();
            $reservation->update([
                'status' => 'checked_in',
                'checked_in_at' => $now,
            ]);

            // Update Table to occupied
            Table::find($reservation->table_id)->update(['status' => 'occupied']);

            $this->dispatch('toast', text: "Kehadiran dikonfirmasi. Meja #{$reservation->table_id} sekarang Terisi.", type: 'success');
        }
    }

    public function completeReservation(int $id): void
    {
        $reservation = Reservation::find($id);
        if ($reservation) {
            $now = now();
            $reservation->update([
                'status' => 'completed',
                'completed_at' => $now,
            ]);

            // Update Table to available
            if ($reservation->table_id) {
                Table::find($reservation->table_id)->update(['status' => 'available']);
            }

            $this->dispatch('toast', text: "Reservasi selesai. Meja #{$reservation->table_id} sekarang Tersedia.", type: 'success');
        }
    }

    public function cancelReservation(int $id, string $reason = ''): void
    {
        $reservation = Reservation::find($id);
        if ($reservation) {
            $now = now();
            $reservation->update([
                'status' => 'cancelled',
                'cancel_reason' => $reason ?: 'Dibatalkan oleh staf (meja penuh/keperluan operasional).',
                'updated_at' => $now,
            ]);
            
            // Update Table to available
            if ($reservation->table_id) {
                Table::find($reservation->table_id)->update(['status' => 'available']);
            }

            // Broadcast event to refresh Livewire dashboards
            event(new \App\Events\ReservationCreated());

            $this->dispatch('toast', text: "Reservasi #{$id} dibatalkan: " . ($reason ?: 'Meja penuh'), type: 'success');
        }
    }

    public function openCancelModal(int $id): void
    {
        $this->cancelReservationId = $id;
        $this->cancelReasonInput = '';
        $this->showCancelModal = true;
    }

    public function closeCancelModal(): void
    {
        $this->showCancelModal = false;
        $this->cancelReservationId = 0;
        $this->cancelReasonInput = '';
    }

    public function submitCancelReservation(): void
    {
        $this->validate([
            'cancelReasonInput' => 'required|string|min:3',
        ], [
            'cancelReasonInput.required' => 'Alasan pembatalan wajib diisi.',
            'cancelReasonInput.min' => 'Alasan pembatalan minimal 3 karakter.',
        ]);

        $this->cancelReservation($this->cancelReservationId, $this->cancelReasonInput);
        $this->closeCancelModal();
    }

    public function render()
    {
        $activeOrdersCount = Order::whereNotIn('status', ['completed', 'cancelled'])->count();
        $activeReservationsCount = Reservation::whereIn('status', ['booked', 'checked_in'])->count();

        $ordersQuery = Order::with(['customer', 'table'])->orderBy('created_at', 'desc');
        if ($this->orderFilter !== 'all') {
            $ordersQuery->where('status', $this->orderFilter);
        }
        $orders = $ordersQuery->get();

        $reservationsQuery = Reservation::with(['customer', 'table'])->orderBy('reservation_date', 'asc');
        if ($this->reservationFilter !== 'all') {
            $reservationsQuery->where('status', $this->reservationFilter);
        }
        if (!empty($this->reservationSearch)) {
            $searchTerm = '%' . trim($this->reservationSearch) . '%';
            $cleanSearchTerm = str_ireplace('JK-RES-', '', trim($this->reservationSearch));
            $reservationsQuery->where(function($query) use ($searchTerm, $cleanSearchTerm) {
                $query->where('id', 'like', $cleanSearchTerm)
                      ->orWhereHas('customer', function($q) use ($searchTerm) {
                          $q->where('name', 'like', $searchTerm);
                      });
            });
        }
        $reservations = $reservationsQuery->get();

        // ponytail: preload once, not per-row in blade
        $availableTables = Table::whereNull('deleted_at')->orderBy('id')->get();
        $availableOnlyTables = $availableTables->where('status', 'available');

        return view('pages.pegawai.dashboard', [
            'activeOrdersCount' => $activeOrdersCount,
            'activeReservationsCount' => $activeReservationsCount,
            'orders' => $orders,
            'reservations' => $reservations,
            'availableTables' => $availableTables,
            'availableOnlyTables' => $availableOnlyTables,
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
                <p class="text-coffee-muted text-sm mt-1">Selamat bekerja, {{ auth()->user()->name }}. Monitor operasional hari ini.</p>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-2 gap-6 mb-8 max-sm:grid-cols-1">
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Pesanan Aktif</h3>
                        <div class="text-3xl font-bold text-coffee-primary font-outfit">{{ $activeOrdersCount }}</div>
                    </div>
                </div>
                <div class="bg-gradient-to-br from-neutral-900 to-neutral-950 border border-coffee-border rounded-xl p-6 flex justify-between items-center shadow-lg">
                    <div>
                        <h3 class="text-xs text-coffee-muted uppercase tracking-wider font-semibold mb-1">Reservasi Aktif</h3>
                        <div class="text-3xl font-bold text-coffee-primary font-outfit">{{ $activeReservationsCount }}</div>
                    </div>
                </div>
            </div>

            <!-- Quick Guidelines -->
            <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-lg text-coffee-text font-semibold">Panduan Operasional</h2>
                </div>
                <div class="flex flex-col gap-4 mt-2">
                    <div class="flex items-start gap-4 p-4 bg-coffee-bg/40 border border-coffee-border/40 rounded-xl">
                        <div>
                            <div class="font-bold text-coffee-text text-sm mb-1">Navigasi Sidebar Cepat</div>
                            <p class="text-xs text-coffee-muted leading-relaxed">Gunakan menu di samping untuk beralih langsung ke halaman Approve Orders (Pesanan) atau Approve Reservasi (Meja).</p>
                        </div>
                    </div>
                    <div class="flex items-start gap-4 p-4 bg-coffee-bg/40 border border-coffee-border/40 rounded-xl">
                        <div>
                            <div class="font-bold text-coffee-text text-sm mb-1">Update Status Pesanan</div>
                            <p class="text-xs text-coffee-muted leading-relaxed">Pastikan Anda segera memperbarui status pesanan dari Pending ➔ Processing ➔ Preparing ➔ Ready ➔ Completed saat makanan/minuman disajikan.</p>
                        </div>
                    </div>
                    <div class="flex items-start gap-4 p-4 bg-coffee-bg/40 border border-coffee-border/40 rounded-xl">
                        <div>
                            <div class="font-bold text-coffee-text text-sm mb-1">Check In Tamu Reservasi</div>
                            <p class="text-xs text-coffee-muted leading-relaxed">Ketika pelanggan reservasi tiba, klik tombol Tiba di panel reservasi untuk menandai kehadiran mereka dan mengunci meja mereka.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    @endif

    <!-- APPROVE ORDERS (ORDERS) TAB -->
    @if($activeTab === 'orders')
        <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl">
            <div class="flex justify-between items-center mb-6 max-sm:flex-col max-sm:items-stretch max-sm:gap-4">
                <!-- Filters -->
                <div class="flex items-center gap-2">
                    <button wire:click="$set('orderFilter', 'all')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $orderFilter === 'all' ? 'bg-coffee-primary text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Semua</button>
                    <button wire:click="$set('orderFilter', 'pending')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $orderFilter === 'pending' ? 'bg-amber-500 text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Pending</button>
                    <button wire:click="$set('orderFilter', 'preparing')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $orderFilter === 'preparing' ? 'bg-[#3b82f6] text-white border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Preparing</button>
                    <button wire:click="$set('orderFilter', 'ready')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $orderFilter === 'ready' ? 'bg-coffee-success text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Ready</button>
                    <button wire:click="$set('orderFilter', 'completed')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $orderFilter === 'completed' ? 'bg-neutral-700 text-coffee-text border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Completed</button>
                </div>
            </div>

            <!-- Desktop Table View -->
            <div class="hidden md:block overflow-x-auto w-full">
                <table class="w-full border-collapse text-left text-sm">
                    <thead>
                        <tr>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">ID Pesanan</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Pelanggan</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Nomor Meja</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Total</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Pembayaran</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Status</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider text-right">Aksi Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($orders as $order)
                            <tr class="hover:bg-coffee-primary/3">
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-semibold font-mono">#{{ $order->id }}</td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                    {{ $order->customer->name ?? ($order->is_walk_in ? 'Walk-in Customer' : 'Umum') }}
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40">
                                    @if(!$order->table_id)
                                        <select wire:change="assignTable({{ $order->id }}, $event.target.value)" class="bg-black/80 border border-coffee-border rounded-lg px-2.5 py-1 text-xs text-coffee-primary font-semibold focus:outline-none focus:border-coffee-primary cursor-pointer">
                                            <option value="">Pilih Meja</option>
                                            @foreach($availableTables as $tbl)
                                                <option value="{{ $tbl->id }}">
                                                    {{ $tbl->qr_code_ref }} {{ $tbl->status === 'occupied' ? '(Terisi)' : '' }}
                                                </option>
                                            @endforeach
                                        </select>
                                    @else
                                        <span class="font-bold text-coffee-text">{{ $order->table->qr_code_ref }}</span>
                                    @endif
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-primary font-bold">
                                    Rp {{ number_format($order->total_amount, 0, ',', '.') }}
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text capitalize">
                                    {{ $order->payment_method ?? 'Cash' }}
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40">
                                    @if($order->status === 'pending')
                                        <span class="bg-[#f59e0b] text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Pending</span>
                                    @elseif($order->status === 'processing')
                                        <span class="bg-[#6366f1] text-white px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Processing</span>
                                    @elseif($order->status === 'preparing')
                                        <span class="bg-[#3b82f6] text-white px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Preparing</span>
                                    @elseif($order->status === 'ready')
                                        <span class="bg-coffee-success text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Ready</span>
                                    @elseif($order->status === 'completed')
                                        <span class="bg-neutral-500 text-white px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Completed</span>
                                    @else
                                        <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">{{ $order->status }}</span>
                                    @endif
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-right">
                                    <div class="flex justify-end items-center gap-1.5">
                                        @if($order->status === 'pending')
                                            <button wire:click="updateOrderStatus({{ $order->id }}, 'processing')" class="py-1.5 px-3 bg-[#6366f1] text-white rounded font-semibold hover:bg-[#4f46e5] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Terima</button>
                                            <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                                        @elseif($order->status === 'processing')
                                            <button wire:click="updateOrderStatus({{ $order->id }}, 'preparing')" class="py-1.5 px-3 bg-[#3b82f6] text-white rounded font-semibold hover:bg-[#2563eb] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Siapkan</button>
                                            <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                                        @elseif($order->status === 'preparing')
                                            <button wire:click="updateOrderStatus({{ $order->id }}, 'ready')" class="py-1.5 px-3 bg-coffee-success text-black rounded font-semibold hover:bg-coffee-success/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Siap</button>
                                            <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                                        @elseif($order->status === 'ready')
                                            <button wire:click="updateOrderStatus({{ $order->id }}, 'completed')" class="py-1.5 px-3 bg-neutral-600 text-white rounded font-semibold hover:bg-neutral-700 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Sajikan</button>
                                        @elseif($order->table_id && $order->table && $order->table->status === 'occupied')
                                            <button wire:click="freeTable({{ $order->id }})" class="py-1.5 px-3 bg-red-600 text-white rounded font-semibold hover:bg-red-700 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Bebaskan Meja</button>
                                        @else
                                            <span class="text-coffee-muted text-xs">-</span>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center text-coffee-muted py-8">Tidak ada data pesanan yang sesuai filter.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Mobile Card View -->
            <div class="block md:hidden space-y-4">
                @forelse($orders as $order)
                    <div class="bg-black/40 border border-coffee-border/60 rounded-xl p-4 flex flex-col gap-3 shadow-md">
                        <div class="flex justify-between items-center">
                            <span class="font-bold font-mono text-coffee-text">#{{ $order->id }}</span>
                            @if($order->status === 'pending')
                                <span class="bg-[#f59e0b] text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Pending</span>
                            @elseif($order->status === 'processing')
                                <span class="bg-[#6366f1] text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Processing</span>
                            @elseif($order->status === 'preparing')
                                <span class="bg-[#3b82f6] text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Preparing</span>
                            @elseif($order->status === 'ready')
                                <span class="bg-coffee-success text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Ready</span>
                            @elseif($order->status === 'completed')
                                <span class="bg-neutral-500 text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Completed</span>
                            @else
                                <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">{{ $order->status }}</span>
                            @endif
                        </div>

                        <div class="text-xs text-coffee-muted space-y-1.5 py-2.5 border-t border-b border-coffee-border/20 my-1">
                            <div class="flex justify-between">
                                <span>Pelanggan:</span>
                                <span class="font-semibold text-coffee-text">{{ $order->customer->name ?? ($order->is_walk_in ? 'Walk-in' : 'Umum') }}</span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span>Meja:</span>
                                @if(!$order->table_id)
                                    <select wire:change="assignTable({{ $order->id }}, $event.target.value)" class="bg-black border border-coffee-border rounded px-2 py-0.5 text-xs text-coffee-primary font-semibold focus:outline-none focus:border-coffee-primary cursor-pointer">
                                        <option value="">Pilih Meja</option>
                                        @foreach($availableTables as $tbl)
                                            <option value="{{ $tbl->id }}">
                                                {{ $tbl->qr_code_ref }} {{ $tbl->status === 'occupied' ? '(Terisi)' : '' }}
                                            </option>
                                        @endforeach
                                    </select>
                                @else
                                    <span class="font-bold text-coffee-text">{{ $order->table->qr_code_ref }}</span>
                                @endif
                            </div>
                            <div class="flex justify-between">
                                <span>Total:</span>
                                <span class="font-bold text-coffee-primary">Rp {{ number_format($order->total_amount, 0, ',', '.') }}</span>
                            </div>
                            <div class="flex justify-between">
                                <span>Metode:</span>
                                <span class="text-coffee-text capitalize">{{ $order->payment_method ?? 'Cash' }}</span>
                            </div>
                        </div>

                        <div class="flex justify-end flex-wrap gap-1.5 mt-1">
                            @if($order->status === 'pending')
                                <button wire:click="updateOrderStatus({{ $order->id }}, 'processing')" class="py-1.5 px-3 bg-[#6366f1] text-white rounded font-semibold hover:bg-[#4f46e5] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Terima</button>
                                <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                            @elseif($order->status === 'processing')
                                <button wire:click="updateOrderStatus({{ $order->id }}, 'preparing')" class="py-1.5 px-3 bg-[#3b82f6] text-white rounded font-semibold hover:bg-[#2563eb] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Siapkan</button>
                                <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                            @elseif($order->status === 'preparing')
                                <button wire:click="updateOrderStatus({{ $order->id }}, 'ready')" class="py-1.5 px-3 bg-coffee-success text-black rounded font-semibold hover:bg-coffee-success/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Siap</button>
                                <button onclick="if(confirm('Batalkan pesanan #{{ $order->id }}?')) { @this.updateOrderStatus({{ $order->id }}, 'cancelled') }" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Batal</button>
                            @elseif($order->status === 'ready')
                                <button wire:click="updateOrderStatus({{ $order->id }}, 'completed')" class="py-1.5 px-3 bg-neutral-600 text-white rounded font-semibold hover:bg-neutral-700 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Sajikan</button>
                            @elseif($order->table_id && $order->table && $order->table->status === 'occupied')
                                <button wire:click="freeTable({{ $order->id }})" class="py-1.5 px-3 bg-red-600 text-white rounded font-semibold hover:bg-red-700 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">Bebaskan Meja</button>
                            @else
                                <span class="text-coffee-muted text-xs">-</span>
                            @endif
                        </div>
                    </div>
                @empty
                    <div class="text-center text-coffee-muted py-8 text-sm">Tidak ada data pesanan yang sesuai filter.</div>
                @endforelse
            </div>
        </div>
    @endif

    <!-- APPROVE RESERVASI (TABLES RESERVATION) TAB -->
    @if($activeTab === 'reservations')
        <div class="bg-coffee-panel backdrop-blur-md border border-coffee-border rounded-2xl p-8 shadow-2xl">
            <div class="flex justify-between items-center mb-6 max-sm:flex-col max-sm:items-stretch max-sm:gap-4">
                <!-- Filters -->
                <div class="flex items-center gap-2">
                    <button wire:click="$set('reservationFilter', 'all')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $reservationFilter === 'all' ? 'bg-coffee-primary text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Semua</button>
                    <button wire:click="$set('reservationFilter', 'booked')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $reservationFilter === 'booked' ? 'bg-amber-500 text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Booked</button>
                    <button wire:click="$set('reservationFilter', 'checked_in')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $reservationFilter === 'checked_in' ? 'bg-coffee-success text-black border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Telah Tiba</button>
                    <button wire:click="$set('reservationFilter', 'completed')" class="py-1.5 px-3 rounded-lg text-xs font-semibold border transition-all cursor-pointer {{ $reservationFilter === 'completed' ? 'bg-[#3b82f6] text-white border-transparent' : 'text-coffee-muted border-coffee-border/40 hover:bg-white/5 hover:text-coffee-text' }}">Selesai</button>
                </div>

                <!-- Search Bar -->
                <div class="relative w-64 max-sm:w-full">
                    <input type="text" 
                           wire:model.live="reservationSearch" 
                           placeholder="Cari ID Booking / Nama..." 
                           class="w-full py-1.5 px-4 bg-black/60 border border-coffee-border rounded-lg text-xs text-coffee-text placeholder-coffee-muted/50 focus:outline-none focus:border-coffee-primary transition-all">
                </div>
            </div>

            <!-- Desktop Table View -->
            <div class="hidden lg:block overflow-x-auto w-full">
                <table class="w-full border-collapse text-left text-sm">
                    <thead>
                        <tr>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">ID Booking</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Pelanggan</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Meja</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Pax</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Waktu Reservasi</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider">Status</th>
                            <th class="py-3 px-4 text-coffee-primary border-b-2 border-coffee-border font-semibold uppercase text-xs tracking-wider text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($reservations as $res)
                            @php
                                $status = strtolower($res->status);
                                $resDate = $res->reservation_date;
                                // Tandai Expired jika terlambat lebih dari 45 menit dari jadwal
                                $isExpired = ($status === 'booked' || $status === 'pending') && $resDate->copy()->addMinutes(45)->isPast();
                            @endphp
                            <tr class="hover:bg-coffee-primary/3">
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-semibold font-mono">
                                    JK-RES-{{ $res->id }}
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                    <div class="font-semibold">{{ $res->customer->name ?? 'Guest' }}</div>
                                </td>

                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-bold">
                                    @if(!$res->table_id)
                                        @if($status === 'booked')
                                            <select wire:change="assignReservationTable({{ $res->id }}, $event.target.value)" class="bg-black/80 border border-coffee-border rounded-lg px-2 py-1 text-xs text-coffee-primary font-semibold focus:outline-none focus:border-coffee-primary cursor-pointer max-w-[120px]">
                                                <option value="">Pilih Meja</option>
                                                @foreach($availableOnlyTables as $availableTable)
                                                    <option value="{{ $availableTable->id }}">{{ $availableTable->qr_code_ref }} (Cap: {{ $availableTable->capacity }})</option>
                                                @endforeach
                                            </select>
                                        @else
                                            <span class="text-xs text-coffee-muted italic">Meja belum ditentukan</span>
                                        @endif
                                    @else
                                        <div class="flex items-center justify-start gap-1.5 text-coffee-text">
                                            <span>{{ $res->table->qr_code_ref ?? "Meja {$res->table_id}" }}</span>
                                            @if($status === 'booked')
                                                <button wire:click="freeReservationTable({{ $res->id }})" title="Bebaskan Meja" class="p-1 rounded-full text-coffee-danger/70 hover:text-coffee-danger hover:bg-coffee-danger/10 transition-colors cursor-pointer">
                                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"></path></svg>
                                                </button>
                                            @endif
                                        </div>
                                    @endif
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text">
                                    <div class="flex items-center gap-1.5">
                                        <span>{{ $res->pax }} Orang</span>
                                        @if($res->pax > 4)
                                            <span class="text-[10px] text-amber-500 font-bold bg-amber-500/10 border border-amber-500/20 px-1 py-0.5 rounded" title="Kapasitas 1 meja standar adalah 4 orang. Staf harus menambahkan kursi ekstra atau menggabungkan meja.">
                                                >4 Orang
                                            </span>
                                        @endif
                                    </div>
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-coffee-text font-mono text-xs">
                                    {{ $resDate->format('d M Y (H:i)') }}
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40">
                                    @if($isExpired)
                                        <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Expired</span>
                                    @elseif($status === 'booked')
                                        <span class="bg-[#f59e0b] text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Booked</span>
                                    @elseif($status === 'checked_in')
                                        <span class="bg-coffee-success text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Tiba</span>
                                    @elseif($status === 'completed')
                                        <span class="bg-[#3b82f6] text-white px-2 py-1 rounded text-xs font-bold uppercase tracking-wider">Selesai</span>
                                    @else
                                        <span class="bg-coffee-danger text-black px-2 py-1 rounded text-xs font-bold uppercase tracking-wider" @if($res->cancel_reason) title="Alasan: {{ $res->cancel_reason }}" @endif>
                                            {{ $res->status }}
                                            @if($res->cancel_reason)
                                                <svg class="w-3 h-3 inline-block ml-1 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                            @endif
                                        </span>
                                    @endif
                                </td>
                                <td class="py-4 px-4 border-b border-coffee-border/40 text-right">
                                    @if($status === 'booked')
                                        <button wire:click="confirmArrival({{ $res->id }})" class="py-1.5 px-3 bg-coffee-success text-black rounded font-semibold hover:bg-coffee-success/80 shadow-none border-none transition-all text-xs cursor-pointer mr-1">
                                            Tiba
                                        </button>
                                        <button wire:click="openCancelModal({{ $res->id }})" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">
                                            Batal
                                        </button>
                                    @elseif($status === 'checked_in')
                                        <button wire:click="completeReservation({{ $res->id }})" class="py-1.5 px-3 bg-[#3b82f6] text-white rounded font-semibold hover:bg-[#2563eb] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">
                                            Selesai & Bebaskan Meja
                                        </button>
                                    @else
                                        <span class="text-coffee-muted text-xs">-</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center text-coffee-muted py-8">Tidak ada data reservasi yang sesuai filter.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Mobile Card View -->
            <div class="block lg:hidden space-y-4">
                @forelse($reservations as $res)
                    @php
                        $status = strtolower($res->status);
                        $resDate = $res->reservation_date;
                        $isExpired = ($status === 'booked' || $status === 'pending') && $resDate->copy()->addMinutes(45)->isPast();
                    @endphp
                    <div class="bg-black/40 border border-coffee-border/60 rounded-xl p-4 flex flex-col gap-3 shadow-md">
                        <div class="flex justify-between items-center">
                            <span class="font-bold font-mono text-coffee-text">JK-RES-{{ $res->id }}</span>
                            @if($isExpired)
                                <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Expired</span>
                            @elseif($status === 'booked')
                                <span class="bg-[#f59e0b] text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Booked</span>
                            @elseif($status === 'checked_in')
                                <span class="bg-coffee-success text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Tiba</span>
                            @elseif($status === 'completed')
                                <span class="bg-[#3b82f6] text-white px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">Selesai</span>
                            @else
                                <span class="bg-coffee-danger text-black px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider">{{ $res->status }}</span>
                            @endif
                        </div>

                        <div class="text-xs text-coffee-muted space-y-1.5 py-2.5 border-t border-b border-coffee-border/20 my-1">
                            <div class="flex justify-between">
                                <span>Pelanggan:</span>
                                <span class="font-semibold text-coffee-text">{{ $res->customer->name ?? 'Guest' }}</span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span>Meja:</span>
                                @if(!$res->table_id)
                                    @if($status === 'booked')
                                        <select wire:change="assignReservationTable({{ $res->id }}, $event.target.value)" class="bg-black border border-coffee-border rounded px-2 py-0.5 text-xs text-coffee-primary font-semibold focus:outline-none focus:border-coffee-primary cursor-pointer max-w-[120px]">
                                            <option value="">Pilih Meja</option>
                                            @foreach($availableOnlyTables as $availableTable)
                                                <option value="{{ $availableTable->id }}">{{ $availableTable->qr_code_ref }} (Cap: {{ $availableTable->capacity }})</option>
                                            @endforeach
                                        </select>
                                    @else
                                        <span class="text-xs text-coffee-muted italic">Belum ditentukan</span>
                                    @endif
                                @else
                                    <div class="flex items-center gap-1.5 text-coffee-text font-semibold">
                                        <span>{{ $res->table->qr_code_ref ?? "Meja {$res->table_id}" }}</span>
                                        @if($status === 'booked')
                                            <button wire:click="freeReservationTable({{ $res->id }})" title="Bebaskan Meja" class="p-1 rounded-full text-coffee-danger/70 hover:text-coffee-danger hover:bg-coffee-danger/10 transition-colors cursor-pointer">
                                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"></path></svg>
                                            </button>
                                        @endif
                                    </div>
                                @endif
                            </div>
                            <div class="flex justify-between">
                                <span>Pax:</span>
                                <div class="flex items-center gap-1.5 text-coffee-text font-semibold">
                                    <span>{{ $res->pax }} Orang</span>
                                    @if($res->pax > 4)
                                        <span class="text-[9px] text-amber-500 font-bold bg-amber-500/10 border border-amber-500/20 px-1 py-0.5 rounded">>4 Orang</span>
                                    @endif
                                </div>
                            </div>
                            <div class="flex justify-between">
                                <span>Waktu:</span>
                                <span class="font-mono text-coffee-text">{{ $resDate->format('d M Y (H:i)') }}</span>
                            </div>
                        </div>

                        @if($res->cancel_reason)
                            <div class="mt-2 text-xs text-red-400/80 italic font-mono px-4 pb-2 whitespace-normal break-words" title="Alasan Batal: {{ $res->cancel_reason }}">
                                <span class="bg-red-500/10 px-2 py-1 rounded flex items-center gap-1.5 w-fit">
                                    <svg class="w-3 h-3 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                    Alasan Pembatalan
                                </span>
                            </div>
                        @endif

                        <div class="flex justify-end gap-1.5 mt-1">
                            @if($status === 'booked')
                                <button wire:click="confirmArrival({{ $res->id }})" class="py-1.5 px-3 bg-coffee-success text-black rounded font-semibold hover:bg-coffee-success/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">
                                    Tiba
                                </button>
                                <button wire:click="openCancelModal({{ $res->id }})" class="py-1.5 px-3 bg-coffee-danger text-black rounded font-semibold hover:bg-coffee-danger/80 shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">
                                    Batal
                                </button>
                            @elseif($status === 'checked_in')
                                <button wire:click="completeReservation({{ $res->id }})" class="py-1.5 px-3 bg-[#3b82f6] text-white rounded font-semibold hover:bg-[#2563eb] shadow-none border-none transition-all text-xs cursor-pointer disabled:opacity-50" wire:loading.attr="disabled">
                                    Selesai & Bebaskan
                                </button>
                            @else
                                <span class="text-coffee-muted text-xs">-</span>
                            @endif
                        </div>
                    </div>
                @empty
                    <div class="text-center text-coffee-muted py-8 text-sm">Tidak ada data reservasi yang sesuai filter.</div>
                @endforelse
            </div>
        </div>
    @endif

    <!-- Cancellation Reason Modal -->
    @if($showCancelModal)
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md">
            <div class="bg-coffee-panel border border-coffee-border rounded-2xl p-8 max-w-md w-full shadow-2xl">
                <h3 class="text-lg font-bold text-coffee-text mb-4">Batalkan Reservasi</h3>
                <p class="text-xs text-coffee-muted mb-6">Silakan masukkan catatan/alasan penolakan untuk Booking JK-RES-{{ $cancelReservationId }}.</p>
                
                <div class="mb-6">
                    <label for="cancelReasonInput" class="block mb-2 text-sm text-coffee-muted font-medium">Alasan Penolakan</label>
                    <textarea 
                        wire:model="cancelReasonInput" 
                        id="cancelReasonInput" 
                        rows="3" 
                        placeholder="Misal: Meja penuh pada jam tersebut / Kafe tutup lebih awal..." 
                        class="w-full py-2.5 px-4 bg-black/80 border border-coffee-border rounded-lg text-coffee-text text-sm focus:outline-none focus:border-coffee-primary resize-none"
                    ></textarea>
                    @error('cancelReasonInput') 
                        <span class="text-coffee-danger text-xs mt-1.5 block font-medium">{{ $message }}</span> 
                    @enderror
                </div>
                
                <div class="flex justify-end gap-3">
                    <button wire:click="submitCancelReservation" class="py-2 px-5 bg-coffee-danger hover:bg-coffee-danger/80 text-black font-bold text-xs rounded-lg transition-all cursor-pointer">
                        Batalkan Reservasi
                    </button>
                    <button wire:click="closeCancelModal" class="py-2 px-5 bg-transparent border border-coffee-border text-coffee-muted hover:bg-white/5 font-semibold text-xs rounded-lg transition-all cursor-pointer">
                        Kembali
                    </button>
                </div>
            </div>
        </div>
    @endif
</div>
