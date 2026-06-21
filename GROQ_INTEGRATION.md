# TFLite + Groq AI Integration Guide

Panduan untuk mengintegrasikan TFLite (pengenalan uang lokal cepat) dengan Groq AI API (verifikasi berbasis cloud).

## Overview

Sistem hybrid ini menggabungkan:
- **TFLite** (Pengenalan Lokal): Pengenalan cepat tanpa koneksi internet
- **Groq AI** (Verifikasi Cloud): Verifikasi berbasis cloud dengan model vision AI terbaik

## Strategi Pengenalan

1. **Pengenalan dengan TFLite** (Cepat, Lokal)
   - Hasil digunakan langsung jika akurat
   - Tidak memerlukan koneksi internet
   - Respon dalam hitungan detik

2. **Fallback ke Groq AI** (Jika TFLite gagal)
   - Jika TFLite gagal atau confidence rendah, gunakan Groq AI
   - Lebih akurat dengan model vision terbaru
   - Memerlukan koneksi internet dan API key

3. **Error Handling**
   - Jika kedua metode gagal, tampilkan error terperinci
   - User dapat mencoba scan ulang

## Setup

### 1. Dapatkan Groq API Key

1. Kunjungi [console.groq.com](https://console.groq.com)
2. Daftar atau login dengan akun Anda
3. Buka bagian "API Keys"
4. Buat API key baru
5. Copy API key tersebut

### 2. Build APK dengan Groq API Key

```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_groq_api_key_here
```

Contoh:
```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_1234567890abcdefghijklmnop
```

### 3. Build dengan Konfigurasi Lainnya (Opsional)

Anda bisa menggunakan Groq AI dengan Roboflow atau custom recognizer:

```bash
# TFLite + Groq AI
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_key

# TFLite + Groq AI + Roboflow (fallback tertier)
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=your_groq_key \
  --dart-define=RUPIEYE_ROBOFLOW_API_KEY=your_roboflow_key
```

## Arsitektur

```
User Photo
    ↓
TfliteGroqCurrencyRecognizer
    ↓
Try TFLite
    ├─ Success? → Return Result ✓
    └─ Fail/Low Confidence? → Try Groq AI
                                 ↓
                          Groq API Call
                                 ├─ Success? → Return Result ✓
                                 └─ Fail? → Return Error ✗
```

## File-file Baru

### `lib/services/groq_currency_recognizer.dart`
Implementasi recognizer yang memanggil Groq AI API secara langsung:
- Konversi gambar ke base64
- Call Groq Vision API
- Parse respons JSON
- Ekstrak nominal dan confidence

### `lib/services/tflite_groq_currency_recognizer.dart`
Hybrid recognizer yang menggabungkan TFLite dan Groq:
- Coba TFLite terlebih dahulu (cepat)
- Jika gagal, fallback ke Groq AI
- Logging untuk debugging

## Konfigurasi Advanced

### Mengubah Model Groq

Edit `groq_currency_recognizer.dart` untuk menggunakan model berbeda:

```dart
final groqRecognizer = GroqCurrencyRecognizer(
  apiKey: _groqApiKey,
  model: 'meta-llama/llama-4-scout-17b-16e-instruct', // ubah model di sini
);
```

Opsi model yang tersedia:
- `meta-llama/llama-4-scout-17b-16e-instruct` (default, cepat & akurat)
- `gpt-4o-mini` (alternatif, compact)
- `mixtral-8x7b-32768` (alternatif, open-source)

### Mengubah Confidence Threshold

Edit `app.dart` untuk mengubah threshold minimal:

```dart
return TfliteGroqCurrencyRecognizer(
  tfliteRecognizer: offlineRecognizer,
  groqRecognizer: groqRecognizer,
  tfliteHighConfidenceThreshold: 0.85, // ubah dari 0.75
  enableLogging: true,
);
```

## Testing

### Test dengan TFLite Saja
```bash
flutter run
# Tidak perlu --dart-define, akan menggunakan TFLite saja
```

### Test dengan TFLite + Groq AI
```bash
flutter run --dart-define=RUPIEYE_GROQ_API_KEY=your_key
# Akan menggunakan hybrid mode
```

### Lihat Logging

Buka logcat/debug console untuk melihat log pengenalan:
```
[TfliteGroqRecognizer] Memulai pengenalan dengan TFLite...
[TfliteGroqRecognizer] TFLite berhasil: Rp100000
```

## Troubleshooting

### Error: "Groq API Key tidak dikonfigurasi"
**Solusi**: Pastikan Anda memberikan `--dart-define=RUPIEYE_GROQ_API_KEY=xxx` saat build

### Error: "Groq API error (401): Unauthorized"
**Solusi**: API key salah atau expired. Dapatkan key baru dari console.groq.com

### Error: "Groq API error (429): Rate limit exceeded"
**Solusi**: Terlalu banyak request. Tunggu beberapa saat dan coba lagi.

### Aplikasi hanya menggunakan TFLite
**Solusi**: Periksa apakah GROQ_API_KEY sudah diberikan saat build. Prioritas: Groq > Roboflow > Custom URL > TFLite Saja

## API Reference

### GroqCurrencyRecognizer

```dart
GroqCurrencyRecognizer(
  apiKey: String,           // Required: Groq API Key
  model: String,            // Optional: Model name (default: 'meta-llama/llama-4-scout-17b-16e-instruct')
  timeout: Duration,        // Optional: Timeout (default: 30 seconds)
  confidenceThreshold: double, // Optional: Min confidence (default: 0.5)
  maxImageDimension: int,   // Optional: Max image size (default: 1024)
  jpegQuality: int,         // Optional: JPEG quality (default: 78)
)
```

### TfliteGroqCurrencyRecognizer

```dart
TfliteGroqCurrencyRecognizer(
  tfliteRecognizer: CurrencyRecognizer,    // Required: TFLite recognizer
  groqRecognizer: CurrencyRecognizer,      // Required: Groq recognizer
  tfliteHighConfidenceThreshold: double,   // Optional: Confidence threshold (default: 0.75)
  enableLogging: bool,                      // Optional: Enable logging (default: false)
)
```

## Performance

- **TFLite**: ~100-500ms (offline)
- **Groq AI**: ~2-5 detik (online, tergantung koneksi)
- **Hybrid**: ~500ms-5 detik (tergantung keberhasilan TFLite)

## Cost Estimation

Groq AI Vision adalah gratis untuk:
- Unlimited calls untuk free tier
- Baca [pricing](https://console.groq.com/keys) untuk detail terbaru

## Referensi

- [Groq API Documentation](https://console.groq.com/docs/vision)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Flutter Environment Variables](https://flutter.dev/docs/development/build-output)
