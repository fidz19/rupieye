import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

class GroqCurrencyRecognizer implements CurrencyRecognizer {
  GroqCurrencyRecognizer({
    required this.apiKey,
    this.model = 'meta-llama/llama-4-scout-17b-16e-instruct',
    this.timeout = const Duration(seconds: 30),
    this.confidenceThreshold = 0.5,
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

  final String apiKey;
  final String model;
  final Duration timeout;
  final double confidenceThreshold;
  final int maxImageDimension;
  final int jpegQuality;
  final HttpClient _httpClient;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    if (imagePath == null) {
      throw CurrencyRecognitionException(
        'Gambar hasil scan tidak tersedia untuk verifikasi Groq AI.',
      );
    }

    if (apiKey.isEmpty) {
      throw CurrencyRecognitionException(
        'Groq API Key tidak dikonfigurasi.',
      );
    }

    final imageBase64 = await _prepareImageBase64(imagePath);
    final response = await _callGroqApi(imageBase64).timeout(timeout);

    final amount = _extractAmount(response);
    final confidence = _extractConfidence(response);

    if (amount == null || !_allowedDenominations.contains(amount)) {
      throw CurrencyRecognitionException(
        'Groq AI tidak menemukan nominal rupiah yang valid. Respons: $response',
      );
    }

    if (confidence != null && confidence < confidenceThreshold) {
      throw CurrencyRecognitionException(
        'Groq AI tidak cukup yakin. Confidence ${(confidence * 100).toStringAsFixed(1)}%.',
      );
    }

    return CurrencyRecognition(amount: amount);
  }

  Future<String> _prepareImageBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw CurrencyRecognitionException(
        'Foto hasil camera tidak bisa dibaca untuk Groq AI.',
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

  Future<String> _callGroqApi(String imageBase64) async {
    final request = await _httpClient.postUrl(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    );

    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $apiKey');

    final body = jsonEncode(<String, Object?>{
      'model': model,
      'temperature': 0,
      'response_format': {'type': 'json_object'},
      'messages': <Object?>[
        {
          'role': 'system',
          'content':
              'Anda mengidentifikasi pecahan uang rupiah Indonesia. Hanya kembalikan JSON dengan amount (nominal uang) dan confidence (0.0 hingga 1.0).',
        },
        {
          'role': 'user',
          'content': <Object?>[
            {
              'type': 'text',
              'text':
                  'Identifikasi pecahan uang rupiah di gambar ini. amount harus salah satu dari: 1000, 2000, 5000, 10000, 20000, 50000, 100000. confidence antara 0 dan 1. Berikan respons dalam format JSON: {"amount": <number>, "confidence": <number>}',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$imageBase64',
              },
            },
          ],
        },
      ],
    });

    request.write(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw CurrencyRecognitionException(
        'Groq API error (${response.statusCode}): $responseBody',
      );
    }

    return responseBody;
  }

  int? _extractAmount(String response) {
    try {
      final json = jsonDecode(response) as Map<String, Object?>;
      final choices = json['choices'] as List<Object?>?;
      if (choices == null || choices.isEmpty) {
        return null;
      }

      final firstChoice = choices.first as Map<String, Object?>?;
      if (firstChoice == null) {
        return null;
      }

      final message = firstChoice['message'] as Map<String, Object?>?;
      if (message == null) {
        return null;
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return null;
      }

      final parsed = jsonDecode(content) as Map<String, Object?>;
      final amount = parsed['amount'];

      if (amount is int) {
        return amount;
      }

      if (amount is num) {
        return amount.toInt();
      }

      if (amount is String) {
        return int.tryParse(amount);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  double? _extractConfidence(String response) {
    try {
      final json = jsonDecode(response) as Map<String, Object?>;
      final choices = json['choices'] as List<Object?>?;
      if (choices == null || choices.isEmpty) {
        return null;
      }

      final firstChoice = choices.first as Map<String, Object?>?;
      if (firstChoice == null) {
        return null;
      }

      final message = firstChoice['message'] as Map<String, Object?>?;
      if (message == null) {
        return null;
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        return null;
      }

      final parsed = jsonDecode(content) as Map<String, Object?>;
      final confidence = parsed['confidence'];

      if (confidence is double) {
        return confidence;
      }

      if (confidence is num) {
        return confidence.toDouble();
      }

      if (confidence is String) {
        return double.tryParse(confidence);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
