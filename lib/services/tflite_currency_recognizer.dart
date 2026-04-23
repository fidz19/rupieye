import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteCurrencyRecognizer implements CurrencyRecognizer {
  TfliteCurrencyRecognizer({
    required this.modelAssetPath,
    required this.labelsAssetPath,
    this.confidenceThreshold = 0.55,
  });

  final String modelAssetPath;
  final String labelsAssetPath;
  final double confidenceThreshold;

  Interpreter? _interpreter;
  List<int>? _labels;
  Future<void>? _loadingFuture;

  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    if (imagePath == null) {
      throw CurrencyRecognitionException(
        'Gambar hasil scan tidak tersedia untuk diproses model.',
      );
    }

    await _ensureLoaded();

    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null || labels.isEmpty) {
      throw CurrencyRecognitionException(
        'Model TFLite belum berhasil dimuat.',
      );
    }

    final imageBytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw CurrencyRecognitionException(
        'Foto hasil camera tidak bisa dibaca sebagai gambar.',
      );
    }

    final inputTensor = interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    if (inputShape.length < 4) {
      throw CurrencyRecognitionException(
        'Bentuk input model tidak didukung: $inputShape',
      );
    }

    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final inputChannels = inputShape[3];

    final resizedImage = img.copyResize(
      decodedImage,
      width: inputWidth,
      height: inputHeight,
    );

    final input = _buildInputTensor(
      image: resizedImage,
      height: inputHeight,
      width: inputWidth,
      channels: inputChannels,
      inputType: inputTensor.type,
    );

    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    if (outputShape.isEmpty) {
      throw CurrencyRecognitionException(
        'Bentuk output model tidak valid: $outputShape',
      );
    }

    final outputLength = outputShape.reduce((value, element) => value * element);
    final output = _createTensorBuffer(
      outputShape,
      outputTensor.type == TfLiteType.uint8 ? 0 : 0.0,
    );

    interpreter.run(input, output);

    final scores = _flattenTensor(output).map((value) => value.toDouble()).toList(
      growable: false,
    );
    if (scores.isEmpty) {
      throw CurrencyRecognitionException('Model tidak menghasilkan skor prediksi.');
    }

    var bestIndex = 0;
    var bestScore = scores.first;
    for (var index = 1; index < math.min(scores.length, labels.length); index++) {
      if (scores[index] > bestScore) {
        bestScore = scores[index];
        bestIndex = index;
      }
    }

    if (bestScore < confidenceThreshold) {
      throw CurrencyRecognitionException(
        'Model tidak cukup yakin mendeteksi nominal uang. Confidence ${(bestScore * 100).toStringAsFixed(1)}%.',
      );
    }

    return CurrencyRecognition(amount: labels[bestIndex]);
  }

  Future<void> _ensureLoaded() {
    if (_interpreter != null && _labels != null) {
      return Future<void>.value();
    }

    return _loadingFuture ??= _load();
  }

  Future<void> _load() async {
    _interpreter = await Interpreter.fromAsset(modelAssetPath);
    _labels = await _loadLabels(labelsAssetPath);
  }

  Future<List<int>> _loadLabels(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final values = <int>[];

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final parts = trimmed.split(RegExp(r'\s+'));
      final labelToken = parts.length > 1 ? parts.last : parts.first;
      final amount = int.tryParse(labelToken);
      if (amount != null) {
        values.add(amount);
      }
    }

    if (values.isEmpty) {
      throw CurrencyRecognitionException(
        'File labels tidak berisi nominal uang yang valid.',
      );
    }

    return values;
  }

  Object _buildInputTensor({
    required img.Image image,
    required int height,
    required int width,
    required int channels,
    required TfLiteType inputType,
  }) {
    switch (inputType) {
      case TfLiteType.float32:
        return List.generate(1, (_) {
          return List.generate(height, (y) {
            return List.generate(width, (x) {
              final pixel = image.getPixel(x, y);
              final values = <double>[
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
              return values.sublist(0, channels);
            });
          });
        });
      case TfLiteType.uint8:
        return List.generate(1, (_) {
          return List.generate(height, (y) {
            return List.generate(width, (x) {
              final pixel = image.getPixel(x, y);
              final values = <int>[pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
              return values.sublist(0, channels);
            });
          });
        });
      default:
        throw CurrencyRecognitionException(
          'Tipe input model tidak didukung: $inputType',
        );
    }
  }

  Object _createTensorBuffer(List<int> shape, num fillValue) {
    if (shape.isEmpty) {
      return fillValue;
    }

    return List.generate(
      shape.first,
      (_) => _createTensorBuffer(shape.sublist(1), fillValue),
    );
  }

  List<num> _flattenTensor(Object tensor) {
    if (tensor is num) {
      return <num>[tensor];
    }

    if (tensor is List) {
      return tensor
          .expand((value) => _flattenTensor(value))
          .toList(growable: false);
    }

    throw CurrencyRecognitionException(
      'Output tensor tidak bisa dibaca: ${tensor.runtimeType}',
    );
  }
}
