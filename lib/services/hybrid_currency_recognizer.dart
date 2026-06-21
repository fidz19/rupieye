import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

class HybridCurrencyRecognizer implements CurrencyRecognizer {
  HybridCurrencyRecognizer({
    required CurrencyRecognizer offlineRecognizer,
    required CurrencyRecognizer onlineRecognizer,
  }) : _offlineRecognizer = offlineRecognizer,
       _onlineRecognizer = onlineRecognizer;

  final CurrencyRecognizer _offlineRecognizer;
  final CurrencyRecognizer _onlineRecognizer;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    try {
      return await _offlineRecognizer.recognizeCurrency(imagePath: imagePath);
    } catch (offlineError) {
      try {
        return await _onlineRecognizer.recognizeCurrency(imagePath: imagePath);
      } catch (onlineError) {
        throw CurrencyRecognitionException(
          'Offline gagal: $offlineError\nOnline gagal: $onlineError',
        );
      }
    }
  }
}
