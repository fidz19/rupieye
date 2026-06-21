# RUPI-EYE

RUPI-EYE adalah aplikasi Flutter untuk membantu penyandang tunanetra mengenali nominal uang rupiah.

## Flow aplikasi

1. User membuka RUPI-EYE.
2. User melakukan tap pada layar.
3. Camera menangkap frame uang.
4. Model AI mengenali nominal.
5. TTS membacakan hasil, misalnya: `Ini uang dua puluh ribu rupiah`.

## Status implementasi saat ini

- UI utama sudah diganti dari template default menjadi flow aksesibel satu layar.
- State aplikasi sudah mengikuti proses `idle -> capturing -> recognizing -> speaking`.
- TTS sudah disiapkan memakai `flutter_tts`.
- Recognizer offline memakai model TFLite lokal.
- Recognizer hybrid tersedia: offline dulu, lalu fallback online jika `RUPIEYE_ONLINE_RECOGNIZER_URL` diisi.
- Recognizer hybrid juga bisa memakai Roboflow Serverless Hosted API dengan model `deteksi-rupiah/3`.

## Mode hybrid online

Jangan simpan API key Groq di Flutter. Jalankan backend proxy di `backend/groq-proxy`, lalu mulai app dengan URL proxy:

```sh
flutter run --dart-define=RUPIEYE_ONLINE_RECOGNIZER_URL=http://10.0.2.2:8787/recognize-currency
```

## Mode hybrid Roboflow

Jalankan app dengan API key Roboflow. Jangan commit API key ke repository.

```sh
flutter run \
  --dart-define=RUPIEYE_ROBOFLOW_API_KEY=your_roboflow_key
```

Secara default app memakai endpoint `https://serverless.roboflow.com` dan model `deteksi-rupiah/3`. Keduanya bisa dioverride:

```sh
flutter run \
  --dart-define=RUPIEYE_ROBOFLOW_API_KEY=your_roboflow_key \
  --dart-define=RUPIEYE_ROBOFLOW_MODEL_ID=deteksi-rupiah/3
```

## Langkah berikutnya

- Deploy proxy ke backend sungguhan sebelum rilis.
- Tambahkan dataset uang rupiah dengan variasi kondisi pencahayaan dan sudut.
- Tambahkan feedback audio ketika hasil tidak yakin atau uang tidak terdeteksi.
