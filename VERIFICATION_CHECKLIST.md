# 🔍 Verification Checklist - TFLite + Groq Integration

## Pre-Build Verification

- [ ] **Flutter Environment Ready**
  ```bash
  flutter --version
  flutter doctor
  ```
  Pastikan semua setup sudah OK (green checks)

- [ ] **Project Dependencies**
  ```bash
  flutter pub get
  ```
  Pastikan tidak ada error

- [ ] **Code Compilation**
  ```bash
  flutter analyze
  ```
  Pastikan tidak ada error/warning kritis

## Pre-Build Environment

- [ ] **Groq API Key Ready**
  - [ ] Punya akun Groq (https://console.groq.com)
  - [ ] Sudah membuat API Key
  - [ ] API Key format: `gsk_...` (panjang)

- [ ] **Optional: Roboflow API Key** (opsional)
  - [ ] API Key (jika ingin fallback tambahan)

## Build Verification (TFLite Only - Baseline)

```bash
flutter clean
flutter pub get
flutter build apk --release
```

- [ ] Build selesai tanpa error
- [ ] APK dibuat: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] APK size ~80-120MB (normal)

## Build Verification (With Groq)

```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_KEY_HERE
```

- [ ] Build selesai tanpa error
- [ ] APK dibuat
- [ ] APK size sama dengan TFLite only

## Runtime Verification - Development

### Test 1: TFLite Only (Baseline)

```bash
flutter clean
flutter run
```

- [ ] App meluncur tanpa error
- [ ] Scan uang jelas → hasil dari TFLite (~200ms)
- [ ] Nomimal uang yang ditampilkan benar

### Test 2: TFLite + Groq

```bash
flutter run --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_KEY
```

- [ ] App meluncur tanpa error
- [ ] Debug console tidak menunjukkan error
- [ ] Scan uang jelas → hasil dari TFLite (cepat)
- [ ] Log shows: `[TfliteGroqRecognizer] Memulai pengenalan dengan TFLite...`
- [ ] Log shows: `[TfliteGroqRecognizer] TFLite berhasil: Rp...`

### Test 3: Force Groq Fallback

Untuk test fallback ke Groq, ambil foto uang dengan:
- Angle ekstrem
- Cahaya kurang
- Blur/tidak fokus

Expected behavior:
- [ ] TFLite gagal (confidence rendah)
- [ ] Log shows: `[TfliteGroqRecognizer] TFLite gagal: ...`
- [ ] Log shows: `[TfliteGroqRecognizer] Beralih ke verifikasi Groq AI...`
- [ ] Tunggu ~3-5 detik
- [ ] Groq menampilkan hasil yang akurat
- [ ] Log shows: `[TfliteGroqRecognizer] Groq AI berhasil: Rp...`

### Test 4: Internet Connection Test

- [ ] **With Internet**: 
  ```bash
  flutter run --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_KEY
  ```
  - Scan: TFLite cepat
  - Jika gagal: Groq fallback bekerja

- [ ] **Without Internet (Airplane Mode)**:
  ```bash
  flutter run --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_KEY
  ```
  - Scan uang jelas: TFLite bekerja (offline)
  - Scan uang blur: Groq gagal (koneksi tidak ada) → show error
  - App tidak crash

## Code Verification

- [ ] **File Structure**
  ```
  lib/services/
  ├── groq_currency_recognizer.dart (NEW)
  ├── tflite_groq_currency_recognizer.dart (NEW)
  ├── currency_recognizer.dart (existing)
  ├── tflite_currency_recognizer.dart (existing)
  ├── hybrid_currency_recognizer.dart (existing)
  ├── online_currency_recognizer.dart (existing)
  └── ...
  ```
  - [ ] File baru ada di tempat yang benar

- [ ] **app.dart Imports**
  ```dart
  import 'package:rupieye/services/groq_currency_recognizer.dart';
  import 'package:rupieye/services/tflite_groq_currency_recognizer.dart';
  ```
  - [ ] Imports ada dan benar

- [ ] **Environment Variable**
  ```dart
  const _groqApiKey = String.fromEnvironment('RUPIEYE_GROQ_API_KEY');
  ```
  - [ ] Variable sudah ditambah di app.dart

- [ ] **Recognizer Priority**
  - [ ] Groq priority lebih tinggi dari Roboflow
  - [ ] Fallback chain benar: Groq → Roboflow → URL → TFLite

## API Verification (Optional but Recommended)

- [ ] **Groq API Status**
  ```bash
  # Verify API key works
  curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
    -H "Authorization: Bearer gsk_YOUR_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model": "gpt-4o-mini", "messages": [{"role": "user", "content": "test"}]}'
  ```
  - [ ] Response successful (tidak 401/403/429)

- [ ] **Groq Console**
  - [ ] Kunjungi https://console.groq.com
  - [ ] Buka "Usage" tab
  - [ ] Verifikasi usage tercatat setelah app test

## Performance Verification

Create a test spreadsheet:

| Test Case | Expected | Actual | Status |
|-----------|----------|--------|--------|
| TFLite - Clear photo | <500ms | ___ | ✓/✗ |
| TFLite - Blur photo (fail) | Instant fail | ___ | ✓/✗ |
| Groq - Fallback | <6s | ___ | ✓/✗ |
| Groq - API slow | <10s | ___ | ✓/✗ |
| TFLite - No internet | <500ms | ___ | ✓/✗ |
| Groq - No internet | Error | ___ | ✓/✗ |

## Production APK Verification

```bash
flutter build apk --release \
  --dart-define=RUPIEYE_GROQ_API_KEY=gsk_YOUR_KEY
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

- [ ] APK can be installed
- [ ] App can be opened
- [ ] Scanning works correctly
- [ ] No crashes during usage

## Documentation Verification

- [ ] **GROQ_INTEGRATION.md** tersedia
- [ ] **GROQ_QUICK_START.md** tersedia
- [ ] **INTEGRATION_SUMMARY.md** tersedia
- [ ] **build_commands.sh** tersedia
- [ ] Documentation akurat dan mudah diikuti

## Post-Integration Checklist

- [ ] Semua test case PASSED
- [ ] Production APK siap untuk deploy
- [ ] Documentation sudah dibaca dan dipahami
- [ ] API key aman disimpan (tidak di-hardcode)
- [ ] Groq console menunjukkan usage yang expected
- [ ] Team/user sudah diberitahu tentang fitur baru

## Troubleshooting Log

Jika ada yang tidak berjalan, periksa:

1. **Debug Output**
   - [ ] Debug console menunjukkan log yang sesuai
   - [ ] Tidak ada exception yang tidak tertangani

2. **Network**
   - [ ] Internet connection stabil saat test
   - [ ] API endpoint accessible (bukan blocked)

3. **API Key**
   - [ ] API key tidak expired
   - [ ] API key format benar (gsk_...)
   - [ ] API key memiliki permission yang tepat

4. **Flutter/Dart**
   - [ ] SDK version support (>=3.11.0)
   - [ ] Dependencies semua ter-resolve

## Sign-Off

- [ ] **Developer**: Semua test PASSED
- [ ] **QA**: App works as expected
- [ ] **Product Owner**: Feature ready for release
- [ ] **Date**: _______________

---

**Notes**:
```
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

**Created**: 2026-06-22  
**Last Updated**: _________  
**Status**: Ready for testing ✓
