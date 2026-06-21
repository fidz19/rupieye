# Widget Implementation Example

Berikut adalah contoh bagaimana menggunakan TFLite + Groq recognizer dalam Flutter widget.

## 1. Dalam Scan Page

```dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({required this.recognizer});
  
  final CurrencyRecognizer recognizer;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late CameraController _cameraController;
  bool _isProcessing = false;
  String? _statusMessage;
  CurrencyRecognition? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
    );

    await _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processCapturedImage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Memproses gambar...';
      _lastResult = null;
    });

    try {
      // Ambil foto dari camera
      final imageFile = await _cameraController.takePicture();

      // Proses dengan recognizer
      final result = await widget.recognizer.recognizeCurrency(
        imagePath: imageFile.path,
      );

      setState(() {
        _lastResult = result;
        _statusMessage = 'Berhasil! ${result.spokenText}';
      });

      // Tampilkan dialog hasil
      if (mounted) {
        _showResultDialog(result);
      }
    } on CurrencyRecognitionException catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.message}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog(CurrencyRecognition result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Pengenalan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.formattedAmount,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              result.spokenText,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Waktu: ${DateTime.now().difference(result.recognizedAt).inMilliseconds}ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Uang Rupiah')),
      body: Stack(
        children: [
          // Camera Preview
          CameraPreview(_cameraController),

          // Status Text
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage ?? 'Siap untuk scan',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Last Result Display
          if (_lastResult != null)
            Positioned(
              bottom: 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _lastResult!.formattedAmount,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastResult!.spokenText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scan Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _isProcessing ? null : _processCapturedImage,
                backgroundColor:
                    _isProcessing ? Colors.grey : Colors.blue,
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
```

## 2. Integration dalam App Home Page

```dart
class HomePage extends StatelessWidget {
  const HomePage({required this.recognizer});
  
  final CurrencyRecognizer recognizer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RupiEye')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera, size: 64),
            const SizedBox(height: 24),
            const Text('Scan Uang Rupiah Anda'),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanPage(recognizer: recognizer),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Mulai Scan'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 3. Error Handling Kompleks

```dart
class RobustScanPage extends StatefulWidget {
  const RobustScanPage({required this.recognizer});
  
  final CurrencyRecognizer recognizer;

  @override
  State<RobustScanPage> createState() => _RobustScanPageState();
}

class _RobustScanPageState extends State<RobustScanPage> {
  int _retryCount = 0;
  static const _maxRetries = 3;

  Future<void> _processWithRetry(String imagePath) async {
    _retryCount = 0;

    while (_retryCount < _maxRetries) {
      try {
        final result = await widget.recognizer.recognizeCurrency(
          imagePath: imagePath,
        );

        // Success
        _showSuccessDialog(result);
        return;
      } on CurrencyRecognitionException catch (e) {
        _retryCount++;

        if (_retryCount < _maxRetries) {
          // Show retry message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Percobaan ${_retryCount}/$_maxRetries gagal. Retry...'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Wait before retry
          await Future.delayed(const Duration(seconds: 1));
        } else {
          // All retries failed
          _showErrorDialog(e);
          return;
        }
      }
    }
  }

  void _showSuccessDialog(CurrencyRecognition result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Berhasil'),
        content: Text('Uang Anda: ${result.formattedAmount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(CurrencyRecognitionException error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✗ Gagal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengenalan gagal:'),
            const SizedBox(height: 8),
            Text(error.message),
            const SizedBox(height: 16),
            const Text(
              'Solusi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Pastikan uang terlihat jelas'),
            const Text('• Cahaya cukup terang'),
            const Text('• Angle tidak terlalu ekstrem'),
            const Text('• Cek koneksi internet (untuk Groq)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan dengan Retry')),
      // Implementation sama seperti ScanPage di atas
    );
  }
}
```

## 4. Testing Helper

```dart
import 'package:rupieye/services/currency_recognizer.dart';

/// Helper untuk testing recognizer
class RecognizerTester {
  static Future<void> testBothMethods(
    String imagePath, {
    required CurrencyRecognizer tfliteRecognizer,
    required CurrencyRecognizer groqRecognizer,
  }) async {
    print('=== Testing Both Recognition Methods ===');
    print('Image: $imagePath\n');

    // Test TFLite
    print('1. Testing TFLite...');
    try {
      final result = await tfliteRecognizer.recognizeCurrency(
        imagePath: imagePath,
      );
      print('   ✓ TFLite Result: ${result.formattedAmount}');
      print('   ✓ Time: ~200ms');
    } catch (e) {
      print('   ✗ TFLite Error: $e');
    }

    print('');

    // Test Groq
    print('2. Testing Groq AI...');
    try {
      final result = await groqRecognizer.recognizeCurrency(
        imagePath: imagePath,
      );
      print('   ✓ Groq Result: ${result.formattedAmount}');
      print('   ✓ Time: ~3-5s');
    } catch (e) {
      print('   ✗ Groq Error: $e');
    }
  }
}
```

## 5. Monitoring & Analytics

```dart
class RecognitionAnalytics {
  static const _kRecognitionTimes = 'recognition_times';
  static const _kRecognitionErrors = 'recognition_errors';
  static const _kSuccessRate = 'success_rate';

  int _totalAttempts = 0;
  int _successCount = 0;
  List<Duration> _recognitionTimes = [];
  Map<String, int> _errorCounts = {};

  void recordSuccess(Duration duration) {
    _totalAttempts++;
    _successCount++;
    _recognitionTimes.add(duration);
  }

  void recordError(String errorType) {
    _totalAttempts++;
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }

  double get successRate =>
      _totalAttempts > 0 ? (_successCount / _totalAttempts) : 0;

  Duration get averageTime => _recognitionTimes.isEmpty
      ? Duration.zero
      : Duration(
          milliseconds:
              _recognitionTimes.fold<int>(0, (a, b) => a + b.inMilliseconds) ~/ 
              _recognitionTimes.length,
        );

  void printReport() {
    print('=== Recognition Analytics ===');
    print('Total Attempts: $_totalAttempts');
    print('Success Count: $_successCount');
    print('Success Rate: ${(successRate * 100).toStringAsFixed(1)}%');
    print('Average Recognition Time: ${averageTime.inMilliseconds}ms');
    print('Error Breakdown:');
    _errorCounts.forEach((error, count) {
      print('  - $error: $count');
    });
  }
}
```

---

Gunakan contoh-contoh di atas sebagai referensi untuk implementasi di widget Anda. Sesuaikan dengan kebutuhan aplikasi Anda! 🚀
