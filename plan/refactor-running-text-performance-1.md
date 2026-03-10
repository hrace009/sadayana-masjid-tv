---
goal: Optimasi performa Running Text (Marquee) agar berjalan lancar di Android TV spesifikasi rendah
version: '1.0'
date_created: '2026-03-10'
last_updated: '2026-03-10'
owner: Dev Team
status: 'Completed'
tags:
  - performance
  - refactor
  - android-tv
  - running-text
---

# Optimasi Performa Running Text di Android TV

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Running text (marquee) di `StandbyLayout` mengalami jank (patah-patah) pada perangkat Android TV spesifikasi rendah (Android 11, GPU lemah). Analisis kode menemukan **5 akar masalah** yang saling menumpuk. Plan ini menangani masalah dari dampak terbesar ke terkecil dalam 4 fase bertahap.

## Temuan Analisis (Root Cause Summary)

| # | Masalah | Lokasi | Dampak |
|---|---------|--------|--------|
| 1 | **Double `BackdropFilter`** — `GlassmorphismCard` di `StandbyLayout` (sigma 15) + `GlassmorphismCard` default di `RunningTextWidget` (sigma 15) → 2 layer blur | `standby_layout.dart`, `running_text_widget.dart` | **Sangat Tinggi** |
| 2 | **Tidak ada `RepaintBoundary`** — animasi marquee menyebabkan repaint area statis (prayer cards, clock, header) setiap frame | `standby_layout.dart` | **Tinggi** |
| 3 | **`DisplayStateCubit` emit setiap 1 detik** → rebuild seluruh `StandbyLayout` termasuk container blur running text | `display_state_cubit.dart`, `standby_layout.dart` | **Sedang** |
| 4 | **`IslamicBackground` memiliki `ColorFiltered` + `Image.asset`** full-screen yang membebani GPU | `islamic_background.dart` | **Sedang** |
| 5 | **Kecepatan marquee 40 px/s** terlalu tinggi untuk GPU TV lemah di layar 1080p | `standby_layout.dart` | **Rendah** |

---

## 1. Requirements & Constraints

- **REQ-001**: Running text harus berjalan mulus (tanpa jank yang terlihat) pada Android TV Android 11 GPU rendah
- **REQ-002**: Tampilan visual running text di main display tidak boleh berubah signifikan — desain tetap konsisten dengan tema Islamic Glassmorphism
- **REQ-003**: Perubahan harus backward compatible — no breaking change pada parameter publik `RunningTextWidget` yang sudah ada
- **REQ-004**: Preview running text di `RunningTextSection` (halaman Settings) tidak perlu diubah secara visual
- **CON-001**: Tidak boleh mengubah arsitektur `DisplayStateCubit` secara fundamental (outside scope plan ini)
- **CON-002**: `GlassmorphismCard` masih digunakan di banyak tempat lain — perubahan harus additive (tambah parameter baru), bukan memodifikasi default behavior
- **GUD-001**: Gunakan `RepaintBoundary` untuk mengisolasi widget yang dianimasikan secara kontinu dari widget statis
- **GUD-002**: `BackdropFilter` (blur) wajib dihindari pada widget yang dianimasikan terus-menerus di perangkat TV
- **PAT-001**: Ikuti pattern Clean Code — perubahan minimal, tidak ada refactoring di luar target masalah

---

## 2. Implementation Steps

### Implementation Phase 1 — Eliminasi BackdropFilter pada Footer Running Text

Fase ini adalah **perbaikan terdampak terbesar** dan paling _surgical_. Dua layer `BackdropFilter` sigma-15 yang bertumpuk di atas animasi marquee adalah penyebab utama jank GPU. Target: nol layer blur pada running text di main display.

- **GOAL-001**: Hapus `BackdropFilter` dari footer running text di `StandbyLayout` dan cegah double-wrap dari `RunningTextWidget`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Tambah parameter `useBlur: bool` ke `GlassmorphismCard` dengan default `true` agar backward compatible. Saat `useBlur: false`, widget menggunakan `Container` solid tanpa `BackdropFilter` dan tanpa `ClipRRect` | ✅ | 2026-03-10 |
| TASK-002 | Update footer di `StandbyLayout` — ganti `GlassmorphismCard` wrapper dengan `Container` solid menggunakan `IslamicColors.glassWhite` + border `IslamicColors.glassBorder` + `BorderRadius.circular(16.r)` (tanpa blur, tanpa ClipRRect) | ✅ | 2026-03-10 |
| TASK-003 | Pada call `RunningTextWidget` di `StandbyLayout`, tambahkan `showBackground: false` — karena wrapper solid sudah dibuat di TASK-002, tidak perlu background tambahan dari widget | ✅ | 2026-03-10 |

**Catatan TASK-002**: Penampilan visual akan sedikit berbeda — container footer tidak transparan/blur lagi, melainkan solid semi-transparan. Ini adalah trade-off yang disengaja demi performa. Warna `IslamicColors.glassWhite` sudah semi-transparan sehingga tetap terlihat harmonis.

---

### Implementation Phase 2 — Tambah RepaintBoundary

Fase ini mengisolasi layer animasi marquee dari widget statis di sekitarnya, mencegah Flutter me-repaint prayer cards, clock, dan header setiap kali marquee bergerak satu pixel.

- **GOAL-002**: Isolasi widget animasi kontinu (running text & jam detik) menggunakan `RepaintBoundary`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Bungkus seluruh footer running text di `StandbyLayout` dengan `RepaintBoundary`. `RepaintBoundary` diletakkan di **luar** wrapper Container (menjadi parent langsung dari container footer) | ✅ | 2026-03-10 |
| TASK-005 | Bungkus `DigitalClockWidget` di `StandbyLayout` dengan `RepaintBoundary`. Jam detik diperbarui setiap 1 detik — tanpa boundary, setiap update detik berpotensi me-repaint seluruh row body | ✅ | 2026-03-10 |

---

### Implementation Phase 3 — Turunkan Kecepatan Marquee

Minor tweak untuk mengurangi delta pergeseran per-frame. Pergeseran yang lebih kecil per-frame berarti lebih sedikit area yang perlu di-composite ulang oleh GPU.

- **GOAL-003**: Turunkan kecepatan marquee di main display ke nilai yang optimal untuk GPU TV lemah

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Ubah `scrollSpeed` pada call `RunningTextWidget` di `StandbyLayout` dari `40.0` menjadi `30.0` pixels/detik | ✅ | 2026-03-10 |
| TASK-007 | Ubah default `scrollSpeed` di `RunningTextWidget` dari `50.0` menjadi `30.0` — karena konteks utama widget ini adalah main display TV dimana kecepatan lebih rendah lebih baik | ✅ | 2026-03-10 |

---

### Implementation Phase 4 — Isolasi Rebuild Running Text dari State Cubit

Fase advanced untuk memutus dependency rebuild antara timer 1-detik `DisplayStateCubit` dan running text. Saat ini, setiap `emit` dari cubit menyebabkan rebuild `StandbyLayout` termasuk container footer running text. Solusinya adalah mengekstrak running text footer menjadi widget tersendiri yang hanya listen ke `SettingsCubit` (bukan `DisplayStateCubit`).

- **GOAL-004**: Running text tidak di-rebuild akibat timer tick 1-detik `DisplayStateCubit`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Ekstrak footer running text dari `StandbyLayout` menjadi widget terpisah `_StandbyRunningTextFooter extends StatelessWidget`. Widget baru ini menerima `runningText` sebagai parameter constructor | ✅ | 2026-03-10 |
| TASK-009 | Pastikan `_StandbyRunningTextFooter` tidak di-rebuild oleh `DisplayStateCubit` — karena menerima `runningText` sebagai `final` String, Flutter's element reconciliation akan skip rebuild jika nilai tidak berubah. Verifikasi ini via Flutter DevTools widget rebuild counter | ✅ | 2026-03-10 |

---

### Implementation Phase 5 — Isolasi Rebuild CPU via `buildWhen` & `DigitalClockWidget` Self-Contained

Fase 1–4 sudah menangani **GPU bottleneck** (hapus blur, `RepaintBoundary`). Fase 5 menargetkan
**CPU rebuild overhead** yang tersisa: `BlocBuilder<DisplayStateCubit>` masih menyebabkan rebuild
seluruh `StandbyLayout` setiap detik meski hanya angka detik jam yang berubah. Solusi duanya
saling mendukung — jam digital mengelola waktu sendiri, sehingga layout aman di-skip rebuild
tiap detik.

- **GOAL-005**: CPU tidak rebuild `StandbyLayout` setiap detik — hanya rebuild saat menit berganti
  atau state type berubah; `DigitalClockWidget` memperbarui detik mandiri tanpa ketergantungan
  pada cubit tick

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Konversi `DigitalClockWidget` dari `StatelessWidget(currentTime: DateTime)` menjadi `StatefulWidget` dengan `Timer.periodic(const Duration(seconds: 1), (_) => setState(() { _now = DateTime.now(); }))` internal. Hapus parameter `currentTime` dari constructor public. Dispose timer di `dispose()`. Update pemanggil di `standby_layout.dart` dari `DigitalClockWidget(currentTime: state.currentTime)` menjadi `DigitalClockWidget()`. | ✅ | 2026-03-10 |
| TASK-011 | Tambah `buildWhen` pada `BlocBuilder<DisplayStateCubit, DisplayState>` di `MainDisplayPage` (sekitar baris 99). Logika: `(prev, next) { if (prev.type != next.type) return true; if (next.type == DisplayStateType.standby) { return (prev as StandbyState).currentTime.minute != (next as StandbyState).currentTime.minute; } return true; }` — StandbyLayout hanya rebuild saat menit berganti; state lain (PreAdzan, Adzan, Iqomah, Sholat, WisdomQuote) selalu rebuild karena menampilkan countdown detik. | ✅ | 2026-03-10 |
| TASK-012 | Cache `masehiDate` di `HeaderWidget` — konversi ke `StatefulWidget`. Tambah `String _masehiDate = ''` dan `int _cachedDay = -1`. Di `initState` dan `didUpdateWidget`: jika `widget.currentTime.day != _cachedDay`, jalankan `DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(widget.currentTime)` lalu update cache. Di `build`: gunakan `_masehiDate` string (bukan inline `DateFormat`). Eliminasi locale lookup yang terjadi setiap detik. | ✅ | 2026-03-10 |

**Catatan ketergantungan TASK-010 → TASK-011**: TASK-010 harus selesai terlebih dahulu. Setelah
`DigitalClockWidget` mandiri, `StandbyLayout` tidak lagi butuh `currentTime` untuk pembaruan detik,
sehingga `buildWhen` per-menit di TASK-011 aman diterapkan tanpa mematikan fungsi jam.

---

## 3. Alternatives

- **ALT-001**: Ganti package `marquee` dengan implementasi custom `ScrollTicker` menggunakan `AnimationController` berbasis `vsync` dengan kontrol FPS manual → Ditolak karena terlalu kompleks, berisiko tinggi, dan package `marquee` sudah cukup optimal secara internal
- **ALT-002**: Hapus efek glassmorphism (blur) dari **seluruh** `GlassmorphismCard` di semua layer → Ditolak karena perubahan terlalu besar dan mengubah identitas visual aplikasi secara keseluruhan; Phase 1 sudah cukup targeted
- **ALT-003**: Implement `dart:ui` `Picture` caching untuk blur → Ditolak karena kompleksitas tinggi dan tidak ada bukti Flutter melakukan auto-cache untuk `BackdropFilter`
- **ALT-004**: Kurangi interval tick `DisplayStateCubit` dari 1 detik ke 2 detik → Ditolak karena akan menyebabkan jam detik tertampil tidak akurat (skip detik)
- **ALT-005**: Gunakan `flutter_smooth` package untuk adaptive frame rate → Ditolak karena package experimental dan tidak stabil untuk production

---

## 4. Dependencies

- **DEP-001**: `marquee: ^2.3.0` — package marquee existing, tidak perlu update
- **DEP-002**: `flutter_screenutil` — digunakan untuk semua sizing (`.r`, `.h`, `.w`), sudah ada
- **DEP-003**: `flutter_bloc` — untuk `BlocBuilder` di `StandbyLayout`, sudah ada

Tidak ada dependency baru yang perlu ditambahkan.

---

## 5. Files

- **FILE-001**: `lib/presentation/widgets/glassmorphism_card.dart` — Tambah parameter `useBlur: bool` (TASK-001)
- **FILE-002**: `lib/presentation/pages/main_display/layouts/standby_layout.dart` — Ganti wrapper GlassmorphismCard footer dengan solid container, tambah `showBackground: false`, tambah `RepaintBoundary` x2, turunkan kecepatan, ekstrak `_StandbyRunningTextFooter` (TASK-002, 003, 004, 005, 006, 008, 009); update pemanggil `DigitalClockWidget` (TASK-010)
- **FILE-003**: `lib/presentation/widgets/running_text_widget.dart` — Update default `scrollSpeed` (TASK-007)
- **FILE-004**: `lib/presentation/widgets/digital_clock_widget.dart` — Konversi ke `StatefulWidget` dengan internal `Timer.periodic` (TASK-010)
- **FILE-005**: `lib/presentation/pages/main_display_page.dart` — Tambah `buildWhen` pada `BlocBuilder<DisplayStateCubit>` (TASK-011)
- **FILE-006**: `lib/presentation/widgets/header_widget.dart` — Konversi ke `StatefulWidget` dengan cache `masehiDate` (TASK-012)

---

## 6. Testing

- **TEST-001**: Jalankan aplikasi di **release mode** (`flutter build apk --release` lalu install) di perangkat Android TV target — verifikasi running text berjalan tanpa jank yang terlihat secara visual
- **TEST-002**: Buka Flutter DevTools → Performance tab → aktifkan "Highlight repaints" → verifikasi footer running text memiliki repaint boundary terpisah (tidak menyebabkan repaint prayer cards atau clock saat marquee bergerak)
- **TEST-003**: Jalankan existing widget test `test/presentation/widgets/running_text_widget_test.dart` — pastikan semua test masih pass setelah perubahan default `scrollSpeed`
- **TEST-004**: Visual check di emulator/device — tampilan footer running text setelah penggantian dari GlassmorphismCard ke solid container tetap terbaca dan harmonis dengan tema
- **TEST-005**: Buka halaman Settings → Running Text — pastikan preview masih berfungsi normal (preview menggunakan `RunningTextWidget` dengan `showBackground: true` default yang tidak berubah)
- **TEST-006**: Verifikasi tidak ada `GlassmorphismCard` dengan `BackdropFilter` aktif pada footer running text — gunakan Flutter DevTools → Widget Inspector
- **TEST-007**: Setelah TASK-010 — buka Flutter DevTools → Widget Rebuild Stats → verifikasi `DigitalClockWidget` rebuild setiap detik **secara mandiri** tanpa menyebabkan rebuild pada `HeaderWidget`, `_PrayerCardsRow`, atau `_StandbyRunningTextFooter` di tree yang sama
- **TEST-008**: Setelah TASK-011 — gunakan Flutter DevTools → Widget Rebuild Stats → verifikasi `StandbyLayout` **tidak rebuild** saat detik berganti (hanya rebuild ketika menit berganti); pastikan layout PreAdzan/Adzan/Iqomah/Sholat/WisdomQuote masih rebuild per detik (countdown masih akurat)

---

## 7. Risks & Assumptions

- **RISK-001**: Penggantian blur dengan solid container pada footer mengubah tampilan visual — warna `IslamicColors.glassWhite` (rgba semi-transparan) tanpa blur akan terlihat sedikit berbeda. Mitigasi: gunakan warna dengan opacity sedikit lebih tinggi agar tetap terlihat sebagai elemen tersendiri di atas background
- **RISK-002**: `RepaintBoundary` menambah satu layer compositor tambahan — di perangkat sangat terbatas, ini bisa kontraproduktif jika area yang diisolasi terlalu besar. Mitigasi: boundary hanya pada footer (area kecil, 60.h) dan clock (widget kecil), bukan seluruh layout
- **RISK-003**: TASK-008 (ekstrak widget) berpotensi mengubah rebuild behavior secara tidak terduga jika ada widget lain yang bergantung pada posisi dalam tree → Mitigasi: tetap dalam scope `StandbyLayout`, tidak memindahkan ke file terpisah
- **ASSUMPTION-001**: Lag yang terlihat memang disebabkan oleh GPU bottleneck (bukan CPU/memory), sehingga optimasi GPU (hapus blur, tambah boundary) adalah pendekatan yang tepat
- **ASSUMPTION-002**: Perangkat target menggunakan Android TV dengan GPU yang tidak mendukung hardware acceleration untuk `BackdropFilter` secara efisien
- **ASSUMPTION-003**: Package `marquee ^2.3.0` sudah menggunakan `AnimationController` dengan `Ticker` yang benar — tidak memicu rebuild Flutter setiap frame, hanya memanggil `markNeedsPaint()` secara langsung
- **RISK-004**: Menghapus parameter `currentTime` dari `DigitalClockWidget` adalah **breaking change** — semua pemanggil harus diupdate. Saat ini hanya 1 pemanggil (`standby_layout.dart`), namun perlu dicek apakah ada pemanggil lain (misal di halaman preview/testing). Mitigasi: lakukan `grep` untuk semua referensi `DigitalClockWidget` sebelum implementasi TASK-010
- **RISK-005**: `buildWhen` yang terlalu ketat di TASK-011 berpotensi menyembunyikan bug — jika `StandbyState` memiliki field selain `currentTime` yang berubah di luar perubahan menit (misal: settings update), layout bisa tampil stale. Mitigasi: kondisi `buildWhen` hanya spesifik untuk `StandbyState`; semua state lain selalu rebuild; khusus StandbyState perlu dipastikan bahwa perubahan settings melewati melalui `SettingsCubit` (bukan `DisplayStateCubit`)
- **ASSUMPTION-004**: `StandbyLayout` tidak menampilkan countdown detik. Hanya `DigitalClockWidget` yang perlu per-detik. Informasi "sisa waktu ke sholat berikutnya" di standby layout ditampilkan dalam satuan menit (bukan detik), sehingga per-menit rebuild sudah cukup akurat secara visual

---

## 8. Related Specifications / Further Reading

- [AGENTS.md — Flutter Testing Patterns](../AGENTS.md)
- [docs/UI_UX_GUIDE.md — Android TV Performance Guidelines](../docs/UI_UX_GUIDE.md)
- [plan/design-ui-components-1.md](design-ui-components-1.md) — Plan awal GlassmorphismCard
- [lib/presentation/widgets/glassmorphism_card.dart](../lib/presentation/widgets/glassmorphism_card.dart)
- [lib/presentation/pages/main_display/layouts/standby_layout.dart](../lib/presentation/pages/main_display/layouts/standby_layout.dart)
- [lib/presentation/widgets/running_text_widget.dart](../lib/presentation/widgets/running_text_widget.dart)
