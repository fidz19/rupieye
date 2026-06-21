# Quick Start: TFLite + Groq AI

## Langkah 1: Dapatkan API Key

1. Buka [console.groq.com](https://console.groq.com)
2. Buat akun & login
3. Buka "API Keys"
4. Klik "Create New API Key"
5. Copy API key (contoh: `gsk_1234567890abcdefghij`)

## Langkah 2: Build APK dengan Groq

```bash
cd /home/fidz/Project/rupieye

flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_API_KEY_HERE
```

Contoh lengkap:
```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_1234567890abcdefghij
```

## Langkah 3: Test dengan Flutter Run

```bash
# Test development dengan Groq
flutter run --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_API_KEY_HERE

# Atau tanpa API key (hanya TFLite)
flutter run
```

## Langkah 4: Scan Uang Rupiah

- Jalankan aplikasi
- Tekan tombol scan
- Arahkan kamera ke uang
- Aplikasi akan:
  1. Coba pengenalan dengan TFLite (cepat, ~200ms)
  2. Jika gagal, gunakan Groq AI (~3 detik)
  3. Tampilkan hasil nominal uang

## Troubleshooting Cepat

| Error | Solusi |
|-------|--------|
| "Groq API Key tidak dikonfigurasi" | Pastikan `--dart-define=RUPIEYE_GROQ_API_KEY=...` |
| "Groq API error (401)" | API key salah, dapatkan yang baru |
| "Groq API error (429)" | Rate limit, tunggu & coba lagi |
| Aplikasi lambat | Kemungkinan internet koneksi. TFLite akan fallback local |

## Arsitektur Hybrid

```
┌─ User take photo ─┐
│                   │
│  ┌─────────────────▼─────────────────┐
│  │  TfliteGroqCurrencyRecognizer    │
│  └─────────────────┬─────────────────┘
│                   │
│        ┌──────────▼───────────┐
│        │   Try TFLite (fast)  │
│        │   ~200ms local       │
│        └──────────┬───────────┘
│                   │
│          ┌────────▼────────┐
│          │ Success?        │
│        Yes│        │No/Low  │
│          │        │confidence
│          │        │
│    ┌─────▼─────┐  │
│    │ RETURN ✓  │  │
│    └───────────┘  │
│                   │
│        ┌──────────▼───────────────┐
│        │  Try Groq AI (accurate)  │
│        │  ~3 seconds + internet   │
│        └──────────┬───────────────┘
│                   │
│          ┌────────▼────────┐
│          │ Success?        │
│        Yes│        │No      │
│          │        │
│    ┌─────▼─────┐  ┌────────▼────────┐
│    │ RETURN ✓  │  │ RETURN ERROR ✗  │
│    └───────────┘  └─────────────────┘
```

## Features

✓ **TFLite**: Pengenalan lokal cepat (100-500ms)  
✓ **Groq AI**: Verifikasi akurat dengan Llama 4 Scout model  
✓ **Hybrid**: Otomatis fallback ke Groq jika TFLite gagal  
✓ **Logging**: Debug mode untuk troubleshooting  
✓ **Error Handling**: Error message terperinci  

## Build Commands Reference

```bash
# Release APK (production)
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_key

# Development (debug)
flutter run \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_key

# TFLite only (no Groq)
flutter run

# Test iOS (jika ada Mac)
flutter build ios \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_key
```

## Files Modified

- `lib/services/groq_currency_recognizer.dart` - NEW: Direct Groq API integration
- `lib/services/tflite_groq_currency_recognizer.dart` - NEW: Hybrid recognizer
- `lib/app.dart` - MODIFIED: Added Groq support with priority system
- `GROQ_INTEGRATION.md` - NEW: Full documentation
- `GROQ_QUICK_START.md` - NEW: This file

## Environment Variables

Saat build, gunakan `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_xxx \
  --dart-define=RUPIEYE_ROBOFLOW_API_KEY=xxx \
  --dart-define=RUPIEYE_ROBOFLOW_MODEL_ID=xxx
```

## Next Steps

1. [x] Dapatkan Groq API Key
2. [x] Build APK dengan Groq
3. [x] Test aplikasi
4. [x] Share dengan pengguna
5. Monitor penggunaan API di https://console.groq.com

Enjoy! 🚀
