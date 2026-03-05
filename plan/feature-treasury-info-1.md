---
goal: "Implementasi Fitur Informasi Kas Masjid — Toggle, Input, dan Display di Main Screen"
version: 1.1
date_created: 2026-03-02
last_updated: 2026-03-03
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, treasury, kas-masjid, settings, ui, display]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mencakup implementasi fitur **Informasi Kas Masjid** — sebuah fitur opsional yang menampilkan saldo kas, pemasukan, dan pengeluaran masjid di halaman utama (Standby Layout). Admin masjid dapat mengaktifkan/menonaktifkan fitur ini dari menu Settings dan memasukkan nilai kas secara manual melalui kolom input numerik.

Fitur ini melintasi seluruh layer arsitektur: database migration, domain entity, data model, cubit logic, settings UI (input), dan main display UI (output).

## Sketsa Mockup

### Standby Layout — Opsi A (Kas di Panel Kanan, di bawah "Sholat Berikutnya")

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  🕌  Masjid Al-Ikhlas                    Senin, 2 Maret 2026 / 1 Ramadan  │  ← HEADER
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                                  │  ┌─────────────────────────────────────┐ │
│                                  │  │  Sholat Berikutnya                  │ │
│      ██████████████              │  │                                     │ │
│      ██  14:35  ██   ← JAM      │  │  ASHAR                              │ │
│      ██████████████              │  │  Dalam waktu 45 Menit               │ │
│                                  │  │  Masuk pada 15:20                   │ │
│                                  │  └─────────────────────────────────────┘ │
│                                  │                                          │
│                                  │  ┌─────────────────────────────────────┐ │
│                                  │  │  💰 Kas Masjid  (hanya jika ON)     │ │
│                                  │  │                                     │ │
│                                  │  │  Saldo       Rp 12.500.000         │ │
│                                  │  │  Pemasukan   Rp  4.200.000  ▲      │ │
│                                  │  │  Pengeluaran Rp  1.800.000  ▼      │ │
│                                  │  └─────────────────────────────────────┘ │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Subuh] [Syuruq] [Dhuha] [Dzuhur] [Ashar ★] [Maghrib] [Isya]            │  ← PRAYER CARDS
├─────────────────────────────────────────────────────────────────────────────┤
│  ►  Selamat datang di Masjid Al-Ikhlas, Mari kita jaga kebersamaan ...     │  ← RUNNING TEXT
└─────────────────────────────────────────────────────────────────────────────┘
```

### Settings Menu — Section "Informasi Kas"

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│  ← Pengaturan                                                                │
├─────────────────────┬────────────────────────────────────────────────────────┤
│  Identitas Masjid   │                                                        │
│  Koreksi Ihtiyat    │   💰  Informasi Kas Masjid                             │
│  Durasi Iqomah      │   ─────────────────────────────────────────────        │
│  Pengaturan Dhuha   │                                                        │
│  Durasi Tampilan    │   Tampilkan Info Kas di Layar Utama                    │
│  Running Text       │   ┌──────────────────────────────────────────┐        │
│  Keamanan (PIN)     │   │  [ OFF ●────────            ]  → [ ON ] │        │
│  ─────────────────  │   └──────────────────────────────────────────┘        │
│ ▶ Informasi Kas  ◀  │                                                        │
│  ─────────────────  │   (Aktifkan untuk menampilkan informasi kas di layar)  │
│  Reset Data         │                                                        │
│                     │   ─────────────────────────────────────────────        │
│                     │                                                        │
│                     │   Saldo Kas (Rp)                                       │
│                     │   ┌──────────────────────────────────┐                │
│                     │   │  12500000                        │  ← text input  │
│                     │   └──────────────────────────────────┘                │
│                     │   Preview: Rp 12.500.000                               │
│                     │                                                        │
│                     │   Pemasukan Periode Ini (Rp)                           │
│                     │   ┌──────────────────────────────────┐                │
│                     │   │  4200000                         │                │
│                     │   └──────────────────────────────────┘                │
│                     │   Preview: Rp 4.200.000                                │
│                     │                                                        │
│                     │   Pengeluaran Periode Ini (Rp)                         │
│                     │   ┌──────────────────────────────────┐                │
│                     │   │  1800000                         │                │
│                     │   └──────────────────────────────────┘                │
│                     │   Preview: Rp 1.800.000                                │
│                     │                                                        │
│  Tutup Pengaturan   │   ✅ Tersimpan otomatis                                │
└─────────────────────┴────────────────────────────────────────────────────────┘
```

## 1. Requirements & Constraints

- **REQ-001**: Fitur kas masjid bersifat **opsional** — harus diaktifkan secara eksplisit dari menu Settings melalui toggle on/off
- **REQ-002**: Saat diaktifkan, admin dapat mengisi 3 nilai numerik: **Saldo Kas**, **Pemasukan**, dan **Pengeluaran** — default semua bernilai `0`
- **REQ-003**: Informasi kas ditampilkan di **Standby Layout** (halaman utama) dalam bentuk GlassmorphismCard di bawah panel "Sholat Berikutnya" (panel kanan)
- **REQ-004**: Saat fitur dinonaktifkan (toggle OFF), card kas **tidak ditampilkan** di halaman utama
- **REQ-005**: Input kas menggunakan `TextField` numerik dengan preview format Rupiah (`Rp x.xxx.xxx`) real-time di bawah setiap field
- **REQ-006**: Semua nilai kas berupa bilangan bulat (integer, satuan Rupiah), tidak memerlukan desimal
- **REQ-007**: Perubahan nilai kas harus auto-save ke database menggunakan mekanisme debounce 500ms yang sudah ada
- **SEC-001**: Input harus divalidasi — hanya menerima angka positif ≥ 0, batas atas `999999999999` (di bawah 1 triliun)
- **CON-001**: Database schema harus di-migrate dari versi 5 ke versi 6 (versi 5 sudah digunakan oleh fitur Sholat Jum'at) tanpa data loss menggunakan `ALTER TABLE`
- **CON-004**: Semua dimensi UI menggunakan `flutter_screenutil` (`.sp`, `.w`, `.h`, `.r`)
- **CON-002**: Interaksi D-Pad sebagai primary input, keyboard numerik muncul saat field aktif
- **CON-003**: Data kas bersifat **snapshot manual** — admin menginput saldo aktual, bukan kalkulasi otomatis pemasukan - pengeluaran
- **GUD-001**: Format tampilan Rupiah menggunakan `NumberFormat` dari package `intl` (sudah tersedia)
- **GUD-002**: Saat toggle OFF, 3 input field di-disable (grey-out) secara visual
- **GUD-003**: Icon yang digunakan — Saldo: `Icons.account_balance_wallet`, Pemasukan: `Icons.arrow_upward` (hijau), Pengeluaran: `Icons.arrow_downward` (merah/oranye)
- **PAT-001**: Mengikuti pattern auto-save via `_debounceSave()` di `SettingsCubit`
- **PAT-002**: Mengikuti pattern `GlassmorphismCard` untuk card display di halaman utama

## 2. Implementation Steps

### Phase 1: Database Migration

- GOAL-001: Menambahkan 4 kolom baru ke tabel `settings` untuk menyimpan data kas masjid

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Increment `_databaseVersion` dari `5` ke `6` di `lib/data/datasources/database_helper.dart` (versi 5 sudah digunakan oleh fitur Sholat Jum'at) | ✅ | 2026-03-03 |
| TASK-002 | Tambahkan blok migration `if (oldVersion < 6)` di method `_onUpgrade()` (setelah blok `oldVersion < 5` milik fitur Jum'at) dengan 4 statement `ALTER TABLE settings ADD COLUMN`: `is_treasury_enabled INTEGER NOT NULL DEFAULT 0`, `treasury_balance INTEGER NOT NULL DEFAULT 0`, `treasury_income INTEGER NOT NULL DEFAULT 0`, `treasury_expense INTEGER NOT NULL DEFAULT 0` | ✅ | 2026-03-03 |
| TASK-003 | Tambahkan 4 kolom yang sama ke DDL `_createTables()` di blok `CREATE TABLE settings` — posisi setelah kolom `sholat_jumat_duration_minutes` (yang sudah ditambahkan oleh fitur Jum'at di v5) agar urutan DDL konsisten dengan migration history | ✅ | 2026-03-03 |

### Phase 2: Domain Entity Update

- GOAL-002: Menambahkan 4 field baru ke `Settings` entity agar domain layer aware terhadap data kas

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Tambahkan 4 field baru di `lib/domain/entities/settings.dart`: `final bool isTreasuryEnabled` (default: `false`), `final int treasuryBalance` (default: `0`), `final int treasuryIncome` (default: `0`), `final int treasuryExpense` (default: `0`) | ✅ | 2026-03-03 |
| TASK-005 | Update constructor `Settings()` — tambahkan 4 named parameter dengan default values yang sesuai | ✅ | 2026-03-03 |
| TASK-006 | Update method `copyWith()` — tambahkan 4 parameter optional baru dan mapping ke constructor | ✅ | 2026-03-03 |
| TASK-007 | Update getter `props` pada `Equatable` — tambahkan 4 field baru ke dalam list | ✅ | 2026-03-03 |

### Phase 3: Data Model Update

- GOAL-003: Menambahkan mapping snake_case ↔ camelCase untuk 4 kolom baru di `SettingsModel`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Update constructor `SettingsModel` di `lib/data/models/settings_model.dart` — tambahkan 4 `super` parameter: `super.isTreasuryEnabled`, `super.treasuryBalance`, `super.treasuryIncome`, `super.treasuryExpense` | ✅ | 2026-03-03 |
| TASK-009 | Update `factory SettingsModel.fromMap()` — tambahkan mapping: `is_treasury_enabled` (int 0/1 → bool), `treasury_balance` (int), `treasury_income` (int), `treasury_expense` (int). Gunakan fallback `?? 0` untuk backward compatibility | ✅ | 2026-03-03 |
| TASK-010 | Update method `toMap()` — tambahkan 4 entries: `'is_treasury_enabled': isTreasuryEnabled ? 1 : 0`, `'treasury_balance': treasuryBalance`, `'treasury_income': treasuryIncome`, `'treasury_expense': treasuryExpense` | ✅ | 2026-03-03 |

### Phase 4: Settings Cubit Logic

- GOAL-004: Menambahkan method update pada `SettingsCubit` untuk mengelola data kas

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-011 | Tambahkan method `void updateTreasuryEnabled(bool enabled)` di `lib/presentation/cubits/settings/settings_cubit.dart` — panggil `_saveField('treasury_enabled', {'is_treasury_enabled': enabled ? 1 : 0})` langsung (tanpa debounce, toggle instan) | ✅ | 2026-03-03 |
| TASK-012 | Tambahkan method `void updateTreasuryBalance(int amount)` — validasi `amount >= 0 && amount <= 999999999999` → `_debounceSave('treasury_balance', {'treasury_balance': amount})` | ✅ | 2026-03-03 |
| TASK-013 | Tambahkan method `void updateTreasuryIncome(int amount)` — validasi `amount >= 0 && amount <= 999999999999` → `_debounceSave('treasury_income', {'treasury_income': amount})` | ✅ | 2026-03-03 |
| TASK-014 | Tambahkan method `void updateTreasuryExpense(int amount)` — validasi `amount >= 0 && amount <= 999999999999` → `_debounceSave('treasury_expense', {'treasury_expense': amount})` | ✅ | 2026-03-03 |

### Phase 5: Treasury Section UI (Settings)

- GOAL-005: Membuat halaman section baru di Settings untuk input data kas masjid

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-015 | Buat file `lib/presentation/pages/settings/sections/treasury_section.dart` | ✅ | 2026-03-03 |
| TASK-016 | Implementasi `TreasurySection` sebagai `StatelessWidget`. Layout: title "Informasi Kas Masjid" + icon `Icons.account_balance_wallet`, deskripsi singkat, lalu konten di bawahnya wrapped dalam `BlocBuilder<SettingsCubit, SettingsState>` | ✅ | 2026-03-03 |
| TASK-017 | Baris pertama: Toggle switch via `FocusableWidget` + `Switch.adaptive`. Label: "Tampilkan Info Kas di Layar Utama". `onChanged` → panggil `settingsCubit.updateTreasuryEnabled(value)` | ✅ | 2026-03-03 |
| TASK-018 | Di bawah toggle: 3 input group dalam `Column`, masing-masing berisi: label teks, `TextField` (`TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`), dan preview teks format Rupiah. Seluruh grup di-disable (opacity 0.4, `IgnorePointer`) saat `isTreasuryEnabled == false` | ✅ | 2026-03-03 |
| TASK-019 | Input group 1 — Label: "Saldo Kas (Rp)", field key: `treasuryBalance`, icon: `Icons.account_balance_wallet`. `onChanged` debounced → `settingsCubit.updateTreasuryBalance(int.tryParse(value) ?? 0)` | ✅ | 2026-03-03 |
| TASK-020 | Input group 2 — Label: "Pemasukan Periode Ini (Rp)", field key: `treasuryIncome`, icon: `Icons.arrow_upward` (warna hijau). `onChanged` debounced → `settingsCubit.updateTreasuryIncome(...)` | ✅ | 2026-03-03 |
| TASK-021 | Input group 3 — Label: "Pengeluaran Periode Ini (Rp)", field key: `treasuryExpense`, icon: `Icons.arrow_downward` (warna oranye). `onChanged` debounced → `settingsCubit.updateTreasuryExpense(...)` | ✅ | 2026-03-03 |
| TASK-022 | Implementasi helper method `String _formatRupiah(int amount)` menggunakan `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)` dari package `intl` — hasilkan format `Rp 12.500.000` | ✅ | 2026-03-03 |

### Phase 6: Register Treasury Section ke Settings Menu

- GOAL-006: Mendaftarkan section baru ke menu Settings agar bisa diakses

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-023 | Update `lib/presentation/pages/settings/settings_menu_page.dart` — tambahkan import `treasury_section.dart` | ✅ | 2026-03-03 |
| TASK-024 | Tambahkan `"Informasi Kas"` ke list `_categories` di posisi sebelum `"Reset Data"` (index 8) | ✅ | 2026-03-03 |
| TASK-025 | Tambahkan `TreasurySection()` ke list `_sections` di posisi yang sesuai (index 8, sebelum `ResetSection()`) | ✅ | 2026-03-03 |

### Phase 7: Treasury Info Widget (Main Display)

- GOAL-007: Membuat widget display kas masjid untuk ditampilkan di Standby Layout

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-026 | Buat file `lib/presentation/widgets/treasury_info_widget.dart` | ✅ | 2026-03-03 |
| TASK-027 | Implementasi `TreasuryInfoWidget` sebagai `StatelessWidget`. Parameters: `int balance`, `int income`, `int expense`. Menggunakan `GlassmorphismCard` sebagai container | ✅ | 2026-03-03 |
| TASK-028 | Layout internal: `Column` → title row ("Kas Masjid" + icon wallet), `SizedBox` separator, lalu 3 baris data: Saldo (putih, font lebih besar), Pemasukan (icon `▲` hijau), Pengeluaran (icon `▼` oranye). Semua nilai diformat Rupiah via `NumberFormat` | ✅ | 2026-03-03 |
| TASK-029 | Gunakan `IslamicTypography` dan `IslamicColors` sesuai design system. Font saldo: `subtitle` size. Font pemasukan/pengeluaran: `body` size | ✅ | 2026-03-03 |

### Phase 8: Integrasi ke Standby Layout

- GOAL-008: Menampilkan `TreasuryInfoWidget` di halaman utama saat fitur diaktifkan

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-030 | Update `lib/presentation/pages/main_display/layouts/standby_layout.dart` — tambahkan import `treasury_info_widget.dart` | ✅ | 2026-03-03 |
| TASK-031 | Di dalam panel kanan (`_buildInfoPanel`), setelah card "Sholat Berikutnya", tambahkan kondisional: jika `settingsState is SettingsLoaded && settingsState.settings.isTreasuryEnabled`, tampilkan `SizedBox(height: 24.h)` + `TreasuryInfoWidget(balance: s.treasuryBalance, income: s.treasuryIncome, expense: s.treasuryExpense)` | ✅ | 2026-03-03 |
| TASK-032 | Refactor `_buildInfoPanel()` agar menerima `Settings?` parameter dari `BlocBuilder` di parent, sehingga data settings tersedia untuk menampilkan kas. Atau pindahkan `BlocBuilder` ke scope yang mencakup info panel | ✅ | 2026-03-03 |

### Phase 9: Unit Tests

- GOAL-009: Memastikan semua perubahan tercakup oleh unit test

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-033 | Update `test/data/models/settings_model_test.dart` — tambahkan assertion untuk 4 field baru di test `fromMap`, `toMap`, dan `round-trip` | ✅ | 2026-03-03 |
| TASK-034 | Update `test/presentation/cubits/settings/settings_cubit_test.dart` — tambahkan test group "Treasury Management" dengan test case: `updateTreasuryEnabled` toggles boolean, `updateTreasuryBalance` saves valid amount, `updateTreasuryIncome` saves valid amount, `updateTreasuryExpense` saves valid amount, invalid amount (negatif) tidak disimpan | ✅ | 2026-03-03 |
| TASK-035 | Buat file `test/presentation/widgets/treasury_info_widget_test.dart` — TEST: widget renders 3 nilai (saldo, pemasukan, pengeluaran) dalam format Rupiah yang benar | ✅ | 2026-03-03 |
| TASK-036 | Buat file `test/presentation/pages/settings/sections/treasury_section_test.dart` — TEST: toggle switch mengubah state, 3 input fields render, input disabled saat toggle OFF | ✅ | 2026-03-03 |
| TASK-037 | Jalankan `flutter test --reporter=expanded` untuk validasi semua test lulus | ✅ | 2026-03-03 |

## 3. Alternatives

- **ALT-001**: Menggunakan `DPadStepper` (increment ±1) untuk input kas — **Ditolak** karena angka kas bisa sangat besar (puluhan juta), increment ±1 tidak praktis. Text field numerik lebih efisien
- **ALT-002**: Kalkulasi otomatis saldo = pemasukan - pengeluaran — **Ditolak** karena data kas bersifat snapshot manual. Admin menginput saldo aktual yang mungkin tidak selalu sama dengan selisih pemasukan-pengeluaran (bisa ada saldo awal dari periode sebelumnya)
- **ALT-003**: Menyimpan data kas di tabel terpisah (`treasury`) — **Ditolak** karena data hanya 4 kolom sederhana (toggle + 3 angka) tanpa relasi atau history. Menambah kolom ke tabel `settings` yang sudah singleton lebih sederhana dan konsisten dengan pattern yang ada
- **ALT-004**: Menampilkan kas di footer bersama running text — **Ditolak** karena area footer terbatas dan sudah digunakan untuk marquee. Panel kanan lebih luas dan secara visual sejajar dengan card "Sholat Berikutnya"
- **ALT-005**: Menggunakan tipe `REAL` (double) untuk menyimpan kas — **Ditolak** karena satuan Rupiah tidak memerlukan desimal. `INTEGER` lebih presisi dan menghindari floating-point rounding issues

## 4. Dependencies

- **DEP-001**: Plan 01 `DatabaseHelper` — Migration infrastructure (`_onUpgrade`, `_createTables`)
- **DEP-008**: Plan Jum'at `feature-jumat-prayer-1` — Database sudah di versi 5, treasury harus menggunakan versi 6
- **DEP-002**: Plan 02 `Settings` entity, `SettingsModel` — Domain dan data model yang akan ditambah field
- **DEP-003**: Plan 11 `SettingsCubit` — Logic layer yang akan ditambah method update
- **DEP-004**: Plan 12 `SettingsMenuPage` — UI menu yang akan ditambah category baru
- **DEP-005**: Plan 13 `StandbyLayout` — Layout utama tempat widget kas ditampilkan
- **DEP-006**: Plan 03-04 Design System — `GlassmorphismCard`, `IslamicColors`, `IslamicTypography`, `FocusableWidget`
- **DEP-007**: Package `intl` (sudah terinstall) — `NumberFormat` untuk format Rupiah

## 5. Files

- **FILE-001**: `lib/data/datasources/database_helper.dart` — [MODIFY] Migration v6 (setelah v5 Jum'at), 4 kolom baru di DDL
- **FILE-002**: `lib/domain/entities/settings.dart` — [MODIFY] 4 field baru, copyWith, props
- **FILE-003**: `lib/data/models/settings_model.dart` — [MODIFY] fromMap/toMap 4 field baru
- **FILE-004**: `lib/presentation/cubits/settings/settings_cubit.dart` — [MODIFY] 4 method update baru
- **FILE-005**: `lib/presentation/pages/settings/settings_menu_page.dart` — [MODIFY] Tambah category "Informasi Kas"
- **FILE-006**: `lib/presentation/pages/settings/sections/treasury_section.dart` — [NEW] Section UI input kas
- **FILE-007**: `lib/presentation/widgets/treasury_info_widget.dart` — [NEW] Widget display kas di main screen
- **FILE-008**: `lib/presentation/pages/main_display/layouts/standby_layout.dart` — [MODIFY] Integrasi widget kas
- **FILE-009**: `test/data/models/settings_model_test.dart` — [MODIFY] Test 4 field baru
- **FILE-010**: `test/presentation/cubits/settings/settings_cubit_test.dart` — [MODIFY] Test group Treasury
- **FILE-011**: `test/presentation/widgets/treasury_info_widget_test.dart` — [NEW] Widget test
- **FILE-012**: `test/presentation/pages/settings/sections/treasury_section_test.dart` — [NEW] Section test

## 6. Testing

- **TEST-001**: `SettingsModel.fromMap()` memetakan 4 kolom treasury baru dengan benar (termasuk fallback default `0`)
- **TEST-002**: `SettingsModel.toMap()` menghasilkan map dengan 4 key treasury yang benar (`is_treasury_enabled`, `treasury_balance`, `treasury_income`, `treasury_expense`)
- **TEST-003**: Round-trip `fromMap → toMap → fromMap` menghasilkan object yang identik termasuk field treasury
- **TEST-004**: `SettingsCubit.updateTreasuryEnabled(true)` menyimpan `is_treasury_enabled = 1` ke repository
- **TEST-005**: `SettingsCubit.updateTreasuryBalance(12500000)` menyimpan nilai yang benar setelah debounce
- **TEST-006**: `SettingsCubit.updateTreasuryIncome(4200000)` menyimpan nilai yang benar setelah debounce
- **TEST-007**: `SettingsCubit.updateTreasuryExpense(1800000)` menyimpan nilai yang benar setelah debounce
- **TEST-008**: Input negatif atau melebihi batas atas (`> 999999999999`) ditolak dan tidak disimpan
- **TEST-009**: `TreasuryInfoWidget` menampilkan 3 nilai dalam format Rupiah yang benar (`Rp 12.500.000`)
- **TEST-010**: `TreasurySection` — toggle switch mengubah state enabled/disabled
- **TEST-011**: `TreasurySection` — 3 input field ter-disable (grey-out) saat toggle OFF
- **TEST-012**: `TreasurySection` — input menerima digit only, menolak huruf dan karakter khusus

**Test Command**: `flutter test --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Input angka besar via D-Pad Android TV bisa tidak ideal — **Mitigasi**: gunakan `TextInputType.number` untuk memunculkan numeric keyboard bawaan TV. Jika keyboard tidak muncul, admin bisa menggunakan USB keyboard
- **RISK-002**: Beberapa remote Android TV tidak memiliki tombol angka — **Mitigasi**: D-Pad navigation tetap bisa mengakses on-screen keyboard yang muncul otomatis saat TextField fokus
- **RISK-003**: Data kas bersifat "trust-based" tanpa validasi silang antar field (saldo ≠ pemasukan - pengeluaran) — **Mitigasi**: Ini by design (CON-003), karena saldo adalah snapshot aktual, bukan kalkulasi
- **ASSUMPTION-001**: Package `intl` sudah terinstall dan tersedia untuk `NumberFormat`
- **ASSUMPTION-002**: Pattern `_debounceSave()` di `SettingsCubit` sudah teruji dan stabil
- **ASSUMPTION-003**: `GlassmorphismCard` yang ada sudah cukup fleksibel untuk menampung layout kas tanpa perlu modifikasi
- **ASSUMPTION-004**: Standby Layout panel kanan memiliki ruang vertikal yang cukup untuk menampung card tambahan (kas) di bawah card "Sholat Berikutnya"

## 8. Related Specifications / Further Reading

- [spec-process-settings.md](../spec/spec-process-settings.md) — SPEC-06: Settings & Content Management
- [spec-design-ui-foundation.md](../spec/spec-design-ui-foundation.md) — SPEC-02: UI Foundation
- [feature-settings-logic-1.md](feature-settings-logic-1.md) — Plan 11: Settings Logic
- [feature-settings-ui-1.md](feature-settings-ui-1.md) — Plan 12: Settings UI
- [feature-main-display-ui-1.md](feature-main-display-ui-1.md) — Plan 13: Main Display UI
