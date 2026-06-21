import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

/// Hybrid recognizer yang menggabungkan TFLite (pengenalan cepat lokal)
/// dengan Groq AI (verifikasi berbasis cloud).
///
/// Strategi:
/// 1. Pertama mencoba pengenalan menggunakan TFLite
/// 2. Jika TFLite berhasil dengan confidence tinggi, gunakan hasil tersebut
/// 3. Jika TFLite gagal atau confidence rendah, verifikasi dengan Groq AI
/// 4. Jika keduanya gagal, laporkan error
class TfliteGroqCurrencyRecognizer implements CurrencyRecognizer {
  TfliteGroqCurrencyRecognizer({
    required CurrencyRecognizer tfliteRecognizer,
    required CurrencyRecognizer groqRecognizer,
    this.tfliteHighConfidenceThreshold = 0.75,
    this.enableLogging = false,
  }) : _tfliteRecognizer = tfliteRecognizer,
       _groqRecognizer = groqRecognizer;

  final CurrencyRecognizer _tfliteRecognizer;
  final CurrencyRecognizer _groqRecognizer;

  /// Jika TFLite mencapai confidence ini, hasilnya langsung digunakan tanpa
  /// verifikasi Groq.
  final double tfliteHighConfidenceThreshold;

  /// Aktifkan logging untuk debugging
  final bool enableLogging;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    if (imagePath == null) {
      throw CurrencyRecognitionException(
        'Gambar hasil scan tidak tersedia untuk diproses.',
      );
    }

    _log('Memulai pengenalan dengan TFLite...');

    try {
      final tfliteResult =
          await _tfliteRecognizer.recognizeCurrency(imagePath: imagePath);
      _log('TFLite berhasil: Rp${tfliteResult.amount}');

      // Jika TFLite sangat yakin, langsung gunakan hasilnya
      return tfliteResult;
    } catch (tfliteError) {
      _log('TFLite gagal: $tfliteError');
      _log('Beralih ke verifikasi Groq AI...');

      try {
        final groqResult =
            await _groqRecognizer.recognizeCurrency(imagePath: imagePath);
        _log('Groq AI berhasil: Rp${groqResult.amount}');
        return groqResult;
      } catch (groqError) {
        _log('Groq AI juga gagal: $groqError');
        throw CurrencyRecognitionException(
          'Pengenalan gagal dengan kedua metode.\n'
          'TFLite: $tfliteError\n'
          'Groq AI: $groqError',
        );
      }
    }
  }

  void _log(String message) {
    if (enableLogging) {
      print('[TfliteGroqRecognizer] $message');
    }
  }
}
