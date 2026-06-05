# 📱 Panduan Belajar SaveStep — Persiapan Presentasi
*Versi 2 — Sudah dikoreksi dan diverifikasi langsung dari kode asli*

---

## 🗺️ BAGIAN 1: GAMBARAN BESAR APLIKASI

SaveStep adalah aplikasi **manajemen keuangan personal** berbasis Flutter. Fitur utamanya terbagi menjadi **4 modul**:

| Modul | Apa yang bisa dilakukan User? |
|:---|:---|
| 💰 **Keuangan (Finance)** | Catat pemasukan & pengeluaran, kelola kategori secara dinamis |
| 🐷 **Tabungan (Savings)** | Buat target tabungan, top-up saldo, pantau progres visual |
| 📅 **Planner** | Buat catatan/jadwal di kalender, lihat hari libur nasional otomatis |
| 👤 **Profil** | Edit profil & foto, ganti tema (Dark/Light), backup & restore data ke cloud |

---

## 🏗️ BAGIAN 2: ARSITEKTUR — KENAPA ADA BANYAK FOLDER?

Bayangkan sebuah **restoran**:

| Folder | Analogi Restoran | Penjelasan |
|:---|:---|:---|
| `screens/` | 🍽️ Ruang Makan | Yang dilihat dan disentuh oleh user (UI) |
| `features/` | 👨‍🍳 Dapur | Logika/otak di balik layar (State & Data) |
| `core/` | 🔧 Gudang & Utilitas | Infrastruktur dasar: database, API, notifikasi |
| `services/` | 💳 Kasir | Autentikasi user (login, register, logout) |
| `widgets/` | 🥄 Peralatan Meja | *Catatan: file placeholder saja, tidak digunakan* |

---

## 📁 BAGIAN 3: PENJELASAN SETIAP FOLDER & FILE

---

### 📄 `main.dart`
**Pintu masuk utama aplikasi.** File pertama yang dijalankan Flutter saat aplikasi dibuka.

Tugasnya:
1. Inisialisasi Firebase (koneksi ke backend)
2. Setup Riverpod (`ProviderScope`) sebagai pengelola state global
3. Menentukan halaman pertama yang muncul (Splash Screen)

> 🗣️ *Jawaban untuk dosen: "main.dart adalah entry point aplikasi. Di sini saya inisialisasi Firebase dan Riverpod sebelum UI pertama ditampilkan."*

---

### 📄 `firebase_options.dart`
**File konfigurasi Firebase** yang dibuat otomatis oleh FlutterFire CLI.
Berisi API Key dan konfigurasi koneksi ke project Firebase Anda (untuk Android, Web, dan Windows).

> ⚠️ File ini tidak boleh diedit manual. Jika ditanya dosen: *"File ini di-generate otomatis oleh tool FlutterFire CLI saat menghubungkan project Flutter dengan Firebase."*

---

## 📁 `lib/core/` — Fondasi / Infrastruktur Aplikasi

Berisi semua "mesin" dasar yang dipakai oleh **semua fitur** secara bersama-sama.

---

### 📁 `core/constants/`
- **`app_colors.dart`**
  Menyimpan semua warna aplikasi (ungu, gradasi, dll) dalam satu tempat terpusat.
  Manfaatnya: jika ingin ganti tema warna, cukup edit **1 file ini** saja, seluruh aplikasi berubah.

---

### 📁 `core/database/` ⭐ (Paling Penting!)
Ini adalah **jantung sistem penyimpanan data** SaveStep. Terdiri dari 4 file:

| File | Fungsi |
|:---|:---|
| `local_database_service.dart` | Simpan/baca data dari **HP (lokal)** menggunakan SharedPreferences |
| `firestore_service.dart` | Simpan/baca data dari **Firebase Cloud** (Firestore) |
| `database_provider.dart` | **Jembatan pintar**: memilih antara lokal atau Firestore berdasarkan status login |
| `sync_service.dart` | Mengurus **Backup** (lokal→cloud) dan **Restore** (cloud→lokal) saat user minta |

> 🗣️ *Jawaban untuk dosen: "Sistem database SaveStep menggunakan pendekatan Offline-First. Semua data disimpan lokal terlebih dahulu melalui `local_database_service`. Saat user login dan menekan tombol backup di halaman Profil, `sync_service` akan menyalin data ke Firestore."*

---

### 📁 `core/network/`
- **`weather_service.dart`**
  Memanggil API cuaca eksternal menggunakan library `dio`.
  Hasilnya (suhu, kondisi cuaca) ditampilkan di halaman Dashboard/Home.

---

### 📁 `core/notifications/`
- **`notification_service.dart`**
  Mengatur jadwal dan pengiriman notifikasi lokal (pengingat planner).
  **Tidak butuh internet** — notifikasi disimpan dan dieksekusi langsung di HP.

---

### 📁 `core/providers/`
- **`theme_provider.dart`** → Mengatur Dark Mode / Light Mode secara global di seluruh aplikasi.
- **`profile_provider.dart`** → Menyimpan dan membaca data profil user (nama, foto profil).

---

### 📁 `core/services/`
- **`storage_service.dart`**
  Placeholder untuk Firebase Storage. Di SaveStep, foto profil disimpan **lokal di HP** saja (bukan di-upload ke cloud), sehingga file ini berperan sebagai provider kosong.

---

### 📁 `core/utils/`
- **`currency_formatter.dart`**
  Fungsi pembantu untuk mengubah angka mentah menjadi format mata uang Rupiah.
  Contoh: `950000` → `Rp 950.000`
  Digunakan di seluruh layar keuangan dan tabungan.

---

## 📁 `lib/features/` — Logika Bisnis Setiap Fitur

Setiap sub-folder mewakili satu fitur besar. Di dalamnya ada 2 lapisan:
- **`data/`** → Provider/Notifier (otak yang mengolah data)
- **`domain/models/`** → Model (cetak biru struktur data)

---

### 📁 `features/auth/data/`
- **`auth_provider.dart`**
  Memantau status login user secara real-time menggunakan Firebase Auth.
  Menjawab pertanyaan: *"Apakah user sedang login? Siapa user-nya? Apakah dia tamu (anonymous)?"*

---

### 📁 `features/dashboard/data/`
- **`weather_provider.dart`**
  Mengambil data cuaca dari `weather_service.dart` dan menyimpannya sebagai state Riverpod.
  Ditampilkan secara otomatis di halaman Home saat aplikasi dibuka.

---

### 📁 `features/finance/` ⭐ (Paling Sering Dibahas di Laporan)

| File | Fungsi |
|:---|:---|
| `data/finance_provider.dart` | **Otak utama fitur keuangan.** Berisi semua logika CRUD: `addTransaction`, `editCategory`, `deleteTransaction`, dll. Ini yang dibahas di Bab 3! |
| `domain/models/transaction_model.dart` | Cetak biru data transaksi: `id`, `title`, `amount`, `category`, `date`, `isIncome` |

---

### 📁 `features/planner/`

| File | Fungsi |
|:---|:---|
| `data/planner_provider.dart` | Otak fitur planner: simpan catatan, kelola kategori catatan |
| `data/holiday_service.dart` | Memanggil API hari libur nasional Indonesia (date.nager.at) dan mengubahnya jadi event di kalender |
| `domain/models/note_model.dart` | Cetak biru data catatan: `id`, `title`, `content`, `date`, `category`, `reminder` |

---

### 📁 `features/savings/`

| File | Fungsi |
|:---|:---|
| `data/savings_provider.dart` | Otak fitur tabungan: CRUD target tabungan, top-up saldo, pin/unpin tabungan favorit |
| `domain/models/savings_model.dart` | Cetak biru data tabungan **+ perhitungan otomatis**: persentase progres, sisa hari, status tercapai |

---

## 📁 `lib/screens/` — Tampilan (UI) Setiap Halaman

Semua yang **dilihat oleh user** ada di sini. Sudah dikelompokkan per fitur.

---

### 📁 `screens/auth/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `splash_screen.dart` | Layar loading pertama saat buka app (animasi logo) |
| `onboarding_screen.dart` | Halaman perkenalan fitur (muncul sekali saat pertama install) |
| `login_screen.dart` | Halaman masuk akun (Email/Password & Google Sign-In) |
| `register_screen.dart` | Halaman daftar akun baru |
| `forgot_password_screen.dart` | Halaman kirim email reset password |

---

### 📁 `screens/dashboard/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `main_screen.dart` | **Kerangka utama aplikasi** — berisi Bottom Navigation Bar, mengelola perpindahan antar modul |
| `home_screen.dart` | Halaman beranda: cuaca hari ini, ringkasan keuangan, daftar catatan planner terkini |
| `widgets/home_carousel.dart` | Komponen carousel (geser kiri-kanan) di halaman beranda untuk navigasi cepat |

---

### 📁 `screens/financial/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `finance_screen.dart` | Halaman utama keuangan: saldo bersih, ringkasan, daftar transaksi, filter kategori |
| `add_transaction_screen.dart` | Form lengkap untuk menambah transaksi baru (judul, nominal, kategori, tanggal) |

---

### 📁 `screens/planner/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `planner_screen.dart` | Halaman kalender interaktif + daftar catatan per tanggal yang dipilih |
| `widgets/add_note_bottom_sheet.dart` | Pop-up (bottom sheet) form tambah/edit catatan yang muncul dari bawah layar |

---

### 📁 `screens/profile/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `profile_screen.dart` | Halaman profil: foto, nama, tombol Backup ke Cloud & Restore dari Cloud |
| `settings_screen.dart` | Halaman pengaturan: toggle Dark Mode, informasi aplikasi |

---

### 📁 `screens/savings/`
| File | Halaman yang Ditampilkan |
|:---|:---|
| `savings_screen.dart` | Halaman daftar semua target tabungan yang dimiliki user |
| `savings_detail_screen.dart` | Halaman detail 1 tabungan: circular progress bar, riwayat top-up, info target |
| `add_savings_screen.dart` | Form buat target tabungan baru (nama, target nominal, periode, gambar) |
| `widgets/add_savings_bottom_sheet.dart` | Pop-up form untuk top-up (menambah) saldo tabungan |

---

## 📁 `lib/services/`
- **`auth_service.dart`**
  Berisi fungsi-fungsi autentikasi yang berkomunikasi langsung dengan **Firebase Auth**:
  - `register()` → Daftar akun baru
  - `login()` → Masuk dengan email & password
  - `signInWithGoogle()` → Masuk dengan akun Google
  - `logout()` → Keluar dari akun

---

## 📁 `lib/widgets/`
> ⚠️ **Catatan Penting:** Kedua file di folder ini **kosong (0 bytes)** — hanya placeholder.

- **`custom_button.dart`** → File kosong. Tombol di setiap layar dibuat langsung menggunakan komponen Material Design 3 bawaan Flutter.
- **`custom_textfield.dart`** → File kosong. Input teks dibuat inline di setiap halaman yang membutuhkannya.

> 🗣️ *Jika dosen bertanya: "Widget kustom dibuat secara inline di setiap halaman menggunakan ElevatedButton dan TextField dari Material Design 3, sehingga tidak memerlukan file komponen terpisah."*

---

## 🔄 BAGIAN 4: ALUR DATA (Cara Kerja di Balik Layar)

### Contoh: User menekan "Simpan Transaksi"

```
User tekan tombol Simpan
        ↓
add_transaction_screen.dart (UI)
    memanggil fungsi →
finance_provider.dart → addTransaction()
    meminta data ke →
database_provider.dart
    "User login asli? → pakai LocalDB dulu"
        ↓
local_database_service.dart
    → Simpan ke SharedPreferences (HP)
        ↓
State diperbarui (state.copyWith)
        ↓
finance_screen.dart → otomatis refresh tampilan (Riverpod)
```

### Contoh: User tekan "Backup ke Cloud" di Profil

```
User tekan Backup
        ↓
profile_screen.dart (UI)
    memanggil →
sync_service.dart → backupToCloud()
    membaca semua data dari →
local_database_service.dart
    lalu mengirim ke →
firestore_service.dart → upload ke Firebase Firestore
        ↓
Selesai — data aman di cloud ✅
```

---

## 🎯 BAGIAN 5: JAWABAN SIAP PAKAI UNTUK SESI TANYA JAWAB

### ❓ "Jelaskan arsitektur aplikasinya!"
> *"SaveStep menggunakan Clean Architecture dengan pendekatan Feature-First. UI dipisah di folder `screens`, logika bisnis di folder `features`, dan infrastruktur dasar di folder `core`. Dengan pemisahan ini, setiap bagian kode memiliki tanggung jawab yang jelas dan tidak saling bergantung secara langsung, sehingga mudah dikembangkan dan di-maintenance."*

### ❓ "Apa bedanya LocalDB dan Firestore di aplikasi ini?"
> *"LocalDB menggunakan SharedPreferences untuk menyimpan data di memori internal HP agar aplikasi tetap bisa digunakan penuh tanpa internet — ini yang disebut Offline-First. Firestore digunakan hanya saat user secara manual menekan tombol Backup di halaman Profil, sehingga data aman meskipun HP-nya berganti atau aplikasinya dihapus."*

### ❓ "Apa itu Riverpod dan kenapa digunakan?"
> *"Riverpod adalah library State Management untuk Flutter. Fungsinya seperti 'penyambung' antara data dan tampilan. Ketika data transaksi berubah, Riverpod otomatis memberi tahu halaman yang menampilkan data tersebut untuk memperbarui tampilannya — tanpa perlu refresh manual."*

### ❓ "Fitur apa yang paling kompleks di aplikasi ini?"
> *"Fitur kategorisasi dinamis dengan Cascading Data Integrity. Ketika user mengubah nama kategori, sistem tidak hanya mengubah nama kategorinya saja, tetapi juga secara otomatis memperbarui semua transaksi lama yang menggunakan kategori tersebut agar data tetap konsisten."*

### ❓ "Kenapa pakai Firebase?"
> *"Firebase dipilih karena merupakan Backend-as-a-Service yang sudah menyediakan sistem autentikasi (Firebase Auth) dan database cloud (Firestore) yang aman dan siap pakai, sehingga saya bisa fokus pada pengembangan fitur tanpa harus membangun server sendiri."*

---

## 📌 BAGIAN 6: 3 FILE TERPENTING YANG HARUS DIPAHAMI BETUL

| Prioritas | File | Kenapa Penting |
|:---:|:---|:---|
| 🥇 1 | `features/finance/data/finance_provider.dart` | Otak utama CRUD keuangan — paling banyak dibahas di Bab 3 laporan |
| 🥈 2 | `core/database/database_provider.dart` | Jantung sistem Offline-First — menentukan lokal vs cloud |
| 🥉 3 | `core/database/sync_service.dart` | Mekanisme Backup & Restore — fitur advanced yang membedakan SaveStep |

---

*Panduan ini dibuat dan diverifikasi langsung dari kode asli project SaveStep — Juni 2026*
