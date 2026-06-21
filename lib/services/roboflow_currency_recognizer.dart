import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

class RoboflowCurrencyRecognizer implements CurrencyRecognizer {
  RoboflowCurrencyRecognizer({
    required this.apiUrl,
    required this.apiKey,
    required this.modelId,
    this.timeout = const Duration(seconds: 20),
    this.confidenceThreshold = 0.4,
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

  final String apiUrl;
  final String apiKey;
  final String modelId;
  final Duration timeout;
  final double confidenceThreshold;
  final HttpClient _httpClient;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    if (imagePath == null) {
      throw CurrencyRecognitionException(
        'Gambar hasil scan tidak tersedia untuk verifikasi Roboflow.',
      );
    }

    final imageBase64 = base64Encode(await File(imagePath).readAsBytes());
    final response = await _postImage(imageBase64).timeout(timeout);
    final prediction = _findBestPrediction(response);

    if (prediction == null) {
      throw CurrencyRecognitionException(
        'Roboflow tidak menemukan nominal rupiah yang valid.',
      );
    }

    if (prediction.confidence < confidenceThreshold) {
      throw CurrencyRecognitionException(
        'Roboflow tidak cukup yakin. Confidence ${(prediction.confidence * 100).toStringAsFixed(1)}%.',
      );
    }

    return CurrencyRecognition(amount: prediction.amount);
  }

  Future<Map<String, Object?>> _postImage(String imageBase64) async {
    final request = await _httpClient.postUrl(_endpoint);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{'image': imageBase64}));

    final response = await request.close();
    final responseText = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CurrencyRecognitionException(
        'Roboflow gagal (${response.statusCode}): $responseText',
      );
    }

    final decoded = jsonDecode(responseText);
    if (decoded is! Map) {
      throw CurrencyRecognitionException(
        'Roboflow mengembalikan respons tidak valid.',
      );
    }

    return decoded.cast<String, Object?>();
  }

  Uri get _endpoint {
    final base = Uri.parse(apiUrl);
    final baseSegments = base.pathSegments.where((segment) {
      return segment.isNotEmpty;
    });
    final modelSegments = modelId.split('/').where((segment) {
      return segment.isNotEmpty;
    });

    return base.replace(
      pathSegments: <String>[...baseSegments, ...modelSegments],
      queryParameters: <String, String>{
        ...base.queryParameters,
        'api_key': apiKey,
        'confidence': confidenceThreshold.toString(),
        'format': 'json',
        'image_type': 'base64',
      },
    );
  }

  _RoboflowPrediction? _findBestPrediction(Map<String, Object?> response) {
    final candidates = <_RoboflowPrediction>[];

    final top = response['top'];
    if (top != null) {
      final amount = _parseAmount(top);
      if (amount != null) {
        candidates.add(
          _RoboflowPrediction(
            amount: amount,
            confidence: _readConfidence(response['confidence']) ?? 1,
          ),
        );
      }
    }

    final predictions = response['predictions'];
    if (predictions is List) {
      for (final prediction in predictions) {
        if (prediction is! Map) {
          continue;
        }

        final amount = _parseAmount(
          prediction['class'] ??
              prediction['class_name'] ??
              prediction['label'],
        );
        final confidence = _readConfidence(
          prediction['confidence'] ?? prediction['class_confidence'],
        );

        if (amount != null && confidence != null) {
          candidates.add(
            _RoboflowPrediction(amount: amount, confidence: confidence),
          );
        }
      }
    } else if (predictions is Map) {
      for (final entry in predictions.entries) {
        final value = entry.value;
        final amount = _parseAmount(entry.key);
        final confidence = value is Map
            ? _readConfidence(value['confidence'])
            : _readConfidence(value);

        if (amount != null && confidence != null) {
          candidates.add(
            _RoboflowPrediction(amount: amount, confidence: confidence),
          );
        }
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) {
      return right.confidence.compareTo(left.confidence);
    });

    return candidates.first;
  }

  int? _parseAmount(Object? rawValue) {
    if (rawValue is num) {
      final amount = rawValue.toInt();
      return _allowedDenominations.contains(amount) ? amount : null;
    }

    if (rawValue is! String) {
      return null;
    }

    final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits);
    if (amount != null && _allowedDenominations.contains(amount)) {
      return amount;
    }

    return null;
  }

  double? _readConfidence(Object? rawValue) {
    if (rawValue is num) {
      return rawValue.toDouble();
    }

    if (rawValue is String) {
      return double.tryParse(rawValue);
    }

    return null;
  }
}

class _RoboflowPrediction {
  const _RoboflowPrediction({required this.amount, required this.confidence});

  final int amount;
  final double confidence;
}
