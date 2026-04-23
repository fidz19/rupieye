import 'dart:async';

import 'package:rupieye/models/currency_recognition.dart';

abstract class CurrencyRecognizer {
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath});
}

class CurrencyRecognitionException implements Exception {
  CurrencyRecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoCurrencyRecognizer implements CurrencyRecognizer {
  DemoCurrencyRecognizer({List<int>? denominations})
    : _denominations =
          denominations ??
          const <int>[1000, 2000, 5000, 10000, 20000, 50000, 100000];

  final List<int> _denominations;
  int _currentIndex = 0;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final amount = _denominations[_currentIndex % _denominations.length];
    _currentIndex += 1;

    return CurrencyRecognition(amount: amount);
  }
}
