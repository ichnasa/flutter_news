# Laporan Testing — US News Flutter App

Tanggal: 19 November 2026

## Lingkungan

| Item | Nilai |
|---|---|
| Flutter | 3.47.2 (stable) |
| Dart | 3.13.2 |
| dio | 5.11.1 |
| Target yang diuji | Chrome/Web dan build Android |
| Perintah konfigurasi | `--dart-define-from-file=config/env.json` |

## Perintah dan Hasil

| Pemeriksaan | Perintah | Hasil |
|---|---|---|
| Analisis statis | `flutter analyze` | **No issues found** |
| Unit + widget test | `flutter test` | **33 test lulus** |
| Build release web | `flutter build web --release --dart-define-from-file=config/env.json` | **Berhasil** (`build/web`) |
| Build Android debug | `flutter build apk --debug --dart-define-from-file=config/env.json` | **Berhasil** (`app-debug.apk`) |
| API sukses (config aplikasi) | `GET /top-headlines?country=us&lang=en&max=1` | HTTP 200, `articles` berisi data |
| API sukses (Indonesia) | `GET /top-headlines?country=id&lang=id&max=1` | HTTP 200, `articles` berisi data |
| API key salah | `apikey=000...000` | HTTP 401 |
| Format key salah | `apikey=salah123` | HTTP 400, pesan malformed |
| Endpoint salah | `GET /top-headline` | HTTP 404 |
| Query kosong | `GET /search?q=` | HTTP 400, `errors.q` |
| UI data | Chrome headless, build release | Daftar berita tampil |
| UI error 401 | Chrome headless, build bad key | "API key salah atau tidak terdaftar." |
| UI error koneksi | Chrome headless, build base URL invalid | "Tidak ada koneksi internet. Periksa jaringan Anda." |
| UI config kosong | Chrome headless, build tanpa define | "Konfigurasi belum diisi..." |

## Cakupan Test

- `test/models_test.dart` — mapping `ArticleModel`, pembersihan `[988 chars]`,
  fallback field null, parsing `NewsResponseModel`, `articles: null`, dan
  `FormatException` untuk tipe yang salah.
- `test/api_exception_test.dart` — seluruh `DioExceptionType` (timeout,
  connectionError, badCertificate, cancel, badResponse, unknown), pemetaan
  400/401/403/404/429/5xx, pesan `errors` berbentuk List/Map, `toString()`,
  dan penyamaran API key.
- `test/news_api_service_test.dart` — validasi kata kunci kosong dan >200 karakter
  tanpa mengirim request.
- `test/widget_test.dart` — `ErrorView`, `ArticleCard`, empat state `HomeView`
  (loading, data, kosong, error), tombol Coba Lagi, ganti kategori, cache
  kategori, pull-to-refresh, dialog pencarian + halaman hasil, halaman
  pencarian (hasil, kosong, error + retry), dan halaman detail.

## Kesesuaian Rubrik Tugas

| Kriteria | Bobot | Status | Bukti |
|---|---:|---|---|
| Implementasi `FutureBuilder` | 30% | **Sesuai** | Empat state ditangani; Future disimpan di `State` dan dibuat di `initState`, bukan di `build()`; diuji di `widget_test.dart` |
| Aplikasi berbasis API | 30% | **Sesuai** | Daftar, kategori, pencarian, detail, dan pull-to-refresh memakai data GNews asli; build web berjalan |
| Error handling | 30% | **Sesuai** | `ApiException` terpusat; >4 pesan berbeda; tombol Coba Lagi berfungsi; 3 screenshot error |
| Struktur dan kerapian kode | 10% | **Sesuai** | Model/service/view/widget/route terpisah; URL dan pesan error tidak diduplikasi; `flutter analyze` bersih |
| Screenshot dua skenario error | — | **Ada** | `screenshots/error_api_key_salah.png`, `error_tidak_ada_koneksi.png`, `error_konfigurasi_kosong.png` |

## Catatan

- Build Android debug berhasil. APK belum dijalankan di emulator/perangkat karena
  tidak ada device Android yang terhubung saat pengujian; build web release sudah
  diuji langsung di Chrome.
- `get` dihapus dari dependensi karena routing memakai `Navigator` bawaan Flutter.
- API key yang sebelumnya tertulis di `lib/config/env.dart` dan
  `config/env.example.json` sudah dihapus. Jika key tersebut pernah dibagikan,
  rotasi key di dashboard GNews.
