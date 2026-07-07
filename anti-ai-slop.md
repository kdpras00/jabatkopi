# Anti-AI-slop rules

Concrete, checkable rules that distinguish "designed by a human who has
shipped product" from "default LLM output." Several rules below are
auto-enforced by the daemon's `lint-artifact` linter — failing an
enforced rule is not a style preference, it is a regression. The
rest are guidance for agents and reviewers and are flagged inline as
"(guidance, not auto-checked)" so the contract with the linter stays
honest.

> Adapted from [refero_skill](https://github.com/referodesign/refero_skill)
> (MIT), tightened to match Open Design's lint surface.

## The seven cardinal sins

These are the patterns the linter blocks at P0 (must-fix):

1. **Default Tailwind indigo as accent** — exactly `#6366f1`, `#4f46e5`,
   `#4338ca`, `#3730a3`, `#8b5cf6`, `#7c3aed`, `#a855f7`. The active
   `DESIGN.md` provides `--accent`; use it. Indigo is the textbook AI
   tell. (The daemon's `lint-artifact` flags any of these as a solid
   accent; keep this list in sync with `AI_DEFAULT_INDIGO` in
   `apps/daemon/src/lint-artifact.ts`.)
2. **Two-stop "trust" gradient on the hero** — purple→blue, blue→cyan,
   indigo→pink. A flat surface + intentional type beats this every
   time.
3. **Emoji as feature icons** — `✨`, `🚀`, `🎯`, `⚡`, `🔥`, `💡`
   inside `<h*>`, `<button>`, `<li>`, or `class*="icon"`. Use
   1.6–1.8px-stroke monoline SVG with `currentColor`.
4. **Sans-serif on display text when the seed binds a serif** — h1/h2
   must use `var(--font-display)`, not a hardcoded Inter / Roboto /
   `system-ui`.
5. **Rounded card with a colored left-border accent** — the canonical
   "AI dashboard tile" shape. Drop either the radius or the left
   border.
6. **Invented metrics** — "10× faster", "99.9% uptime", "3× more
   productive". Either pull from a real source or use a labelled
   placeholder.
7. **Filler copy** — `lorem ipsum`, `feature one / two / three`,
   `placeholder text`, `sample content`. An empty section is a design
   problem to solve with composition, not by inventing words.

## Soft tells (P1 — should fix)

- **Standard "Hero → Features → Pricing → FAQ → CTA" sequence with no
  variation** _(guidance, not auto-checked)_. This is the AI-template
  skeleton; introduce at least one unconventional section (testimonial
  wall as full-bleed quote, pricing as comparison-against-status-quo,
  an inline mini-product-demo).
- **External placeholder image CDNs** (`unsplash.com`, `placehold.co`,
  `placekitten.com`, `picsum.photos`). Fragile and obvious. Use the
  shipped `.ph-img` placeholder class.
- **More than ~12 raw hex values outside `:root`.** Tokens were not
  honoured.
- **`var(--accent)` used 6+ times in the rendered body.** Cap at 2
  visible uses per screen.

## Polish tells (P2 — nice to fix)

- **Sections without `data-od-id`** — comment mode can't target them.
- **Decorative blob / wave SVG backgrounds** _(guidance, not
  auto-checked)_ — meaningless geometry.
- **Perfect symmetric layout with no visual tension** _(guidance, not
  auto-checked)_ — alternating density (one tight section, one
  breathing section) reads as intentional.

## How to add soul without breaking the rules

Aim for **~80% proven patterns + ~20% distinctive choice**. The 20%
should live in:

- One bold visual move — a typography choice, a single color decision,
  an unexpected proportion.
- Voice and microcopy — a button that says "Start tracking" beats one
  that says "Get started".
- One micro-interaction the user will remember — a button press that
  moves 2px, a number that counts up.
- One detail that could only have been put there by someone who used
  the product (a subtle kbd shortcut hint, a status badge with
  product-specific phrasing).

If a reviewer screenshots the artifact and someone outside the project
can identify which product it's from — you have soul. If not, you
shipped a template.

---

## Aturan Tombol & UI — berlaku semua stack (P0 — harus fix)

### 1. Tidak boleh ada efek ripple/bubble/overlay pada tombol teks/link

Setiap tombol yang tidak punya background warna sendiri (tombol teks, link, aksi dialog, navigasi) **WAJIB** menghilangkan efek hover/klik bawaan framework.

| Stack | Cara fix |
|---|---|
| **Flutter** | `TextButton.styleFrom(overlayColor: Colors.transparent)` |
| **Laravel/Blade + Tailwind** | Tidak pakai `<button>` untuk link teks; pakai `<a>` atau tambahkan class `focus:outline-none focus-visible:ring-0` |
| **HTML/CSS** | `button { background: none; border: none; outline: none; }` + `:focus { outline: none; }` |

Contoh Flutter:
```dart
TextButton(
  onPressed: ...,
  style: TextButton.styleFrom(overlayColor: Colors.transparent),
  child: const Text('Batalkan'),
)
```

Contoh Blade/HTML:
```html
<button type="button" class="text-coffee-primary focus:outline-none focus-visible:ring-0">
  Batalkan
</button>
```

### 2. Tombol berwarna = warna solid, bukan transparan/gradient/shadow

- Tombol **merah** → solid merah. TIDAK pakai opacity atau border saja.
- Tombol **hijau** → solid hijau. Tombol **kuning/amber** → solid amber.
- Warna solid yang dimaksud: tombol terisi penuh, teks kontras (biasanya putih atau hitam).

| DILARANG | WAJIB |
|---|---|
| `bg-red-500/15 border border-red-500/30` (Tailwind transparan) | `bg-red-600 text-white` |
| `Colors.red.withOpacity(0.15)` (Flutter) | `Colors.red` atau `Colors.redAccent` |
| `background: rgba(220,38,38,0.15)` (CSS) | `background: #dc2626; color: white` |

### 3. Tombol dalam container berwarna → wajib matikan overlay

Jika sebuah tombol berada **di dalam container yang sudah berwarna**, efek hover/klik bawaan akan muncul sebagai bayangan/bubble di atas warna container. Wajib dimatikan.

| Stack | Cara fix |
|---|---|
| **Flutter** | `overlayColor: Colors.transparent` di `styleFrom` |
| **Tailwind/HTML** | `hover:bg-transparent focus:outline-none` |
| **CSS** | `:hover, :focus, :active { background: transparent; box-shadow: none; outline: none; }` |

### 4. Shadow/elevation pada tombol warna custom → matikan

Framework sering menambahkan shadow bawaan pada tombol yang berwarna. Jika desain memerlukan tampilan flat, selalu matikan.

| Stack | Cara fix |
|---|---|
| **Flutter ElevatedButton** | `elevation: 0` di `ElevatedButton.styleFrom(...)` |
| **Blade/HTML** | `shadow-none` atau hapus class `shadow-*` |
| **CSS** | `box-shadow: none` |

### 5. Gaya tombol konsisten per intent (semua stack)

| Intent | Warna | Teks |
|---|---|---|
| Destruktif (hapus, batalkan, keluar) | Merah solid | Putih |
| Sukses/positif (simpan, konfirmasi) | Hijau solid atau gold | Hitam/gelap |
| Netral/sekunder (kembali, batal) | Teks saja, tanpa background | Abu/putih |
| Utama/CTA | Brand color (caramelGold / coffee-primary) | Hitam/gelap |

### 6. Tidak boleh ada label teknis yang terlihat user (semua stack)

Berlaku di semua stack: form label, kolom tabel, toast, error message, placeholder, heading.

- ❌ Dilarang: "Referensi QR Code", "QR Code Ref", "barcode", "token", "foreign key", "ID (int)"
- ✅ Wajib: "Nomor Meja", "Booking ID", "Kode Unik Meja", "Nomor Pesanan"

---

## AI Code Slop (P0 — Wajib Dihindari / Diganti)

AI sering kali menghasilkan pola (AI Code Slop) yang sekilas terlihat rapi dan bertele-tele, tetapi sebenarnya redundan, rapuh, atau over-engineered. Aturan ini khusus berlaku untuk penulisan kode, komentar, penamaan variabel, hingga deskripsi teknis (commit/PR).

### 1. Komentar Obvious & Redundan
AI sering menulis komentar yang hanya mengulangi (menerjemahkan) apa yang dilakukan oleh baris kode, bukan menjelaskan **alasan (why)** kode tersebut ada.
- ❌ Dilarang: `// Loop through the list of users` atau `// Fetch data from API`
- ✅ Wajib: Tulis komentar untuk menjelaskan keputusan teknis/konteks bisnis, contoh: `// Batch processing untuk menghindari limit API 3rd party (maks 50/req)`

### 2. Penamaan Variabel Terlalu Verbose atau Terlalu Generik
AI cenderung membuat nama variabel yang kaku dan terlalu panjang, atau membuat class dengan nama 'sampah' (Manager, Utils).
- ❌ Dilarang (Verbose): `userAuthenticationStatusFlag`, `customerDataListArray`
- ❌ Dilarang (Generik): `DataProcessor`, `HelperUtils`, `Manager` (tanpa kejelasan konteks).
- ✅ Wajib: Gunakan penamaan standar domain yang ringkas (`isAuthenticated`, `customers`, `PaymentGateway`).

### 3. "Plausible but Wrong" Logic (Vibe Coding)
AI sering membuat kode yang simetris (menghandle branch/edge case yang sebenarnya tidak pernah terjadi di business logic) atau membuat error handling buta.
- ❌ Dilarang: `try { ... } catch (e) { console.error("Error occurred"); }` (Swallowing exceptions tanpa rethrow atau handling yang proper).
- ❌ Dilarang: Boilerplate abstraksi (`AbstractUserFactory`) untuk logic yang sangat sederhana (YAGNI).
- ✅ Wajib: Handle error secara spesifik dan biarkan sistem gagal dengan jelas (fail fast) jika state tidak valid.

### 4. Kata Bersayap (Slop) pada Commit Message & PR
Deskripsi PR atau Commit yang digenerate AI sering dipenuhi _buzzwords_ yang tidak bermakna.
- ❌ Dilarang: "Refactored to enhance maintainability", "Streamlined the process", "Robust solution", "Seamless integration", "Delve", "Leverage".
- ✅ Wajib: Jelaskan langsung secara literal. "Fix N+1 query in user list", "Add missing index on orders table".

### 5. Type Hinting & DocBlock Redundan (Over-Annotation)
AI sering menambahkan anotasi tipe data yang sudah jelas (inferrable) atau menulis komentar DocBlock yang hanya mengulang _type signature_.
- ❌ Dilarang: `/** @param string $name \n @return string */ public function getName(string $name): string`
- ✅ Wajib: Biarkan _type hinting_ native (PHP/TS) yang bekerja. Gunakan DocBlock hanya untuk _constraint_ khusus (misal array shape `@return User[]` atau `@throws`).

### 6. Over-Engineering & Premature Abstraction
AI sangat suka menerapkan Design Patterns (Repository, Service, Interface) padahal fungsionalitasnya sangat sepele (misal sekadar CRUD).
- ❌ Dilarang: Membuat `ProductRepositoryInterface` dan `ProductRepositoryImpl` hanya untuk satu query standar `Product::find($id)`.
- ✅ Wajib: Gunakan pendekatan paling simpel yang berfungsi (YAGNI). Refactor ke _pattern_ yang lebih kompleks HANYA jika _business logic_-nya sudah membesar.

### 7. Logging Sampah (Excessive Tracing Logging)
AI sering menaruh log sembarangan di awal dan akhir fungsi, memenuhi server log dengan informasi yang tidak berguna.
- ❌ Dilarang: `Log::info("Entering calculateTotal function");` atau `console.log("Data fetched successfully");`
- ✅ Wajib: Log hanya pada titik krusial bisnis (pembayaran, audit trail), error handling, atau respons API pihak ketiga, disertai parameter ID relevan.

### 8. Fake "TODOs" & Placeholder Kosong
Terkadang AI "malas" merampungkan keseluruhan instruksi kompleks dan menyembunyikan logic aslinya di balik komentar TODO.
- ❌ Dilarang: Meninggalkan kode seperti `// TODO: Implement the actual calculation` atau mengembalikan nilai dummy `return true; // placeholder` tanpa sepengetahuan developer.
- ✅ Wajib: Jika suatu fungsi belum selesai, selalu lempar Exception (misal `throw new Exception('Not Implemented')`) agar terdeteksi, jangan dibiarkan _silent pass_.

### 9. Nested Ternary & "Smart" One-Liners
Agar terlihat efisien, AI sering memaksa logic bertingkat masuk ke dalam 1 baris kode (nested ternary) yang sangat sulit dibaca manusia.
- ❌ Dilarang: `const status = isPaid ? (isDelivered ? 'Done' : 'Shipping') : (isCancelled ? 'Failed' : 'Pending');`
- ✅ Wajib: Utamakan _readability_. Gunakan block `if-else` biasa, operator `match` (PHP 8), atau _early returns_ agar kode mudah dibaca sekilas.

### 10. Reinventing the Wheel (Mengabaikan Standard Library)
AI sering membuat fungsi panjang (_custom_) untuk menyelesaikan hal yang padahal sudah tersedia secara _native_ di _standard library_ bahasa atau framework (Ponytail Rule: _Stdlib does it? Use it_).
- ❌ Dilarang: Looping manual 10 baris untuk mencari _unique value_, memformat tanggal, atau melakukan _deep merge_ array.
- ✅ Wajib: Selalu prioritaskan *native method*. Gunakan helper bawaan seperti `Arr::flatten()` (Laravel), `array_unique` (PHP), atau `.reduce()` (JS). Pendekatan "lazy" selalu menang.

### 11. Custom Code vs Native Platform Feature
AI suka merekomendasikan _dependency_ (library eksternal) baru atau regex rumit alih-alih memanfaatkan fitur bawaan browser/database (Ponytail Rule: _Native platform feature covers it?_).
- ❌ Dilarang: Membawa library `Moment.js`/`Datepicker` raksasa untuk _input date_, atau membuat Regex super kompleks untuk mengecek validasi email.
- ✅ Wajib: Cukup gunakan `<input type="date">` / `<input type="email">`, atau delegasikan konstrain ke tingkat database. Solusi 1 baris > 50 baris setup _library_.

### 12. Boilerplate "Buat Nanti" (Speculative Need)
AI sering membuat struktur yang rumit atau banyak kolom ekstra karena "mungkin di masa depan akan dipakai".
- ❌ Dilarang: Menambahkan 5 file _config_, opsi _flags_, atau argumen seperti `$is_active = true, $metadata = []` yang bahkan belum digunakan di fitur saat ini.
- ✅ Wajib: **YAGNI (You Aren't Gonna Need It)**. Hapus apapun yang tidak langsung digunakan saat ini. _The best code is the code never written_. Hapus spekulasi!

### 13. Ghost Variables (Variabel Hantu)
AI punya kebiasaan mendeklarasikan variabel sementara yang tidak ada fungsinya selain untuk langsung di-_return_ atau dikirim ke fungsi lain di baris berikutnya.
- ❌ Dilarang: `$result = User::find($id); return $result;`
- ✅ Wajib: Langsung _return_ hasilnya: `return User::find($id);`. Kurangi jumlah _state_ dan memori!

### 14. Over-defensive Programming (Pengecekan Paranoid)
Karena tidak yakin dengan bentuk datanya, AI sering mengecek secara berlebihan sebelum mengakses properti objek, membuat kode dipenuhi cabang *if-else* yang dalam.
- ❌ Dilarang: `if (data && data.user && data.user.address) { return data.user.address; }`
- ✅ Wajib: Gunakan sintaks modern bahasa seperti *Optional Chaining* (`data?.user?.address`) atau *Nullish Coalescing* (`??`). Percayakan pada sistem bawaan!

### 15. Blind / Heavy Imports (Ketergantungan Buta)
Untuk mencari jalan pintas, AI terkadang meng-_import_ library utilitas berukuran masif (seperti lodash atau jQuery) hanya untuk melakukan hal super sepele yang ada bawaannya.
- ❌ Dilarang: `import _ from 'lodash';` lalu hanya dipakai satu kali untuk `_.isString()`.
- ✅ Wajib: Lakukan pengecekan *native* (`typeof x === 'string'`) atau setidaknya lakukan *tree-shaking* `import { isString } from 'lodash'`.

### 16. Arrow Code / Pyramid of Doom (Anti-Guard Clauses)
AI sangat suka membuat struktur kode `if/else` bersarang yang makin lama makin menjorok ke kanan, merusak prisip _Clean Code_ karena sulit dilacak batasnya.
- ❌ Dilarang: `if (isValid) { if (hasPermission) { if (isPaid) { return true; } } }`
- ✅ Wajib: Terapkan **Guard Clauses (Early Returns)**. Lakukan pengecekan error/kondisi negatif di awal, lalu langsung _return_. `if (!isValid) return false; if (!hasPermission) return false; return true;`.

### 17. Magic Numbers & Hardcoded Strings
AI sering secara asal "menebak" atau menulis statis angka/string yang seharusnya dikelola tersentral. Hal ini akan menjadi bom waktu saat sistem membesar.
- ❌ Dilarang: Menulis `if ($user->status == 3)` atau `if (role === 'super_admin')` yang tersebar di belasan file berbeda.
- ✅ Wajib: Gunakan `Enum`, `Const`, atau konfigurasi terpusat. Contoh: `if ($user->status == UserStatus::ACTIVE)` sehingga mudah di-_refactor_.

### 18. God Functions (Pelanggaran Single Responsibility)
Ketika di-prompt untuk membuat fitur komprehensif, AI cenderung mencurahkan seluruh logika (validasi, pemanggilan API/DB, perhitungan, formatting return) ke dalam **satu fungsi raksasa 200 baris**.
- ❌ Dilarang: Controller method yang bercampur aduk melakukan semuanya tanpa diekstrak sama sekali.
- ✅ Wajib: Patuhi _Single Responsibility Principle_. Pecah menjadi helper, *form request*, atau *action/service classes* kecil yang punya satu tugas spesifik.
