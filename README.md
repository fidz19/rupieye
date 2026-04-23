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
- Recognizer masih berupa simulasi nominal agar alur end-to-end bisa diuji lebih dulu.

## Langkah berikutnya

- Integrasikan `camera` untuk preview dan pengambilan frame.
- Sambungkan model AI klasifikasi nominal rupiah.
- Tambahkan dataset uang rupiah dengan variasi kondisi pencahayaan dan sudut.
- Tambahkan feedback audio ketika hasil tidak yakin atau uang tidak terdeteksi.
