import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

class OnlineCurrencyRecognizer implements CurrencyRecognizer {
  OnlineCurrencyRecognizer({
    required this.endpoint,
    this.timeout = const Duration(seconds: 20),
    this.confidenceThreshold = 0.45,
    this.maxImageDimension = 1024,
    this.jpegQuality = 78,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  static const Set<int> _allowedDenominations = <int>{
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
    100000,
  };

  final Uri endpoint;
  final Duration timeout;
  final double confidenceThreshold;
  final int maxImageDimension;
  final int jpegQuality;
  final HttpClient _httpClient;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    if (imagePath == null) {
      throw CurrencyRecognitionException(
        'Gambar hasil scan tidak tersedia untuk verifikasi online.',
      );
    }

    final imageBase64 = await _prepareImageBase64(imagePath);
    final response = await _postJson(<String, Object?>{
      'imageBase64': imageBase64,
      'mediaType': 'image/jpeg',
    }).timeout(timeout);

    final amount = _readAmount(response);
    final confidence = _readConfidence(response);

    if (amount == null || !_allowedDenominations.contains(amount)) {
      throw CurrencyRecognitionException(
        'Verifikasi online tidak menemukan nominal rupiah yang valid.',
      );
    }

    if (confidence != null && confidence < confidenceThreshold) {
      throw CurrencyRecognitionException(
        'Verifikasi online tidak cukup yakin. Confidence ${(confidence * 100).toStringAsFixed(1)}%.',
      );
    }

    return CurrencyRecognition(amount: amount);
  }

  Future<String> _prepareImageBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw CurrencyRecognitionException(
        'Foto hasil camera tidak bisa dibaca untuk verifikasi online.',
      );
    }

    final longestSide = math.max(decodedImage.width, decodedImage.height);
    final resizedImage = longestSide <= maxImageDimension
        ? decodedImage
        : img.copyResize(
            decodedImage,
            width: decodedImage.width >= decodedImage.height
                ? maxImageDimension
                : null,
            height: decodedImage.height > decodedImage.width
                ? maxImageDimension
                : null,
          );

    final encodedJpeg = img.encodeJpg(resizedImage, quality: jpegQuality);
    return base64Encode(encodedJpeg);
  }

  Future<Map<String, Object?>> _postJson(Map<String, Object?> body) async {
    final request = await _httpClient.postUrl(endpoint);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));

    final response = await request.close();
    final responseText = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CurrencyRecognitionException(
        'Verifikasi online gagal (${response.statusCode}): $responseText',
      );
    }

    final decoded = jsonDecode(responseText);
    if (decoded is! Map) {
      throw CurrencyRecognitionException(
        'Verifikasi online mengembalikan respons tidak valid.',
      );
    }

    return decoded.cast<String, Object?>();
  }

  int? _readAmount(Map<String, Object?> response) {
    final value = response['amount'];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  double? _readConfidence(Map<String, Object?> response) {
    final value = response['confidence'];
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
