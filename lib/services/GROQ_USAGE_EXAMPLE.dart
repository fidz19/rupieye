import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/groq_currency_recognizer.dart';
import 'package:rupieye/services/tflite_currency_recognizer.dart';
import 'package:rupieye/services/tflite_groq_currency_recognizer.dart';

/// Contoh penggunaan TFLite + Groq AI Integration
void main() {
  // Contoh 1: Membuat recognizer dengan manual setup
  demonstrateManualSetup();

  // Contoh 2: Menggunakan recognizer di praktik
  demonstrateUsage();
}

/// Contoh 1: Setup Manual TFLite + Groq AI
void demonstrateManualSetup() {
  print('=== Contoh 1: Setup Manual ===\n');

  // Setup TFLite recognizer
  final tfliteRecognizer = TfliteCurrencyRecognizer(
    modelAssetPath: 'assets/models/rupieye_float32.tflite',
    labelsAssetPath: 'assets/models/labels.txt',
    confidenceThreshold: 0.55,
  );

  // Setup Groq AI recognizer
  const groqApiKey = 'gsk_your_api_key_here';
  final groqRecognizer = GroqCurrencyRecognizer(
    apiKey: groqApiKey,
    model: 'gpt-4o-mini', // model yang digunakan
    timeout: const Duration(seconds: 30),
    confidenceThreshold: 0.5,
  );

  // Kombinasikan kedua recognizer
  final hybridRecognizer = TfliteGroqCurrencyRecognizer(
    tfliteRecognizer: tfliteRecognizer,
    groqRecognizer: groqRecognizer,
    tfliteHighConfidenceThreshold: 0.75,
    enableLogging: true, // aktifkan logging untuk debugging
  );

  print('✓ Recognizer berhasil dibuat');
  print('  - TFLite: Pengenalan lokal cepat');
  print('  - Groq AI: Verifikasi dengan AI vision');
  print('  - Mode: Hybrid (TFLite → Groq jika diperlukan)\n');
}

/// Contoh 2: Menggunakan Recognizer dalam aplikasi
void demonstrateUsage() async {
  print('=== Contoh 2: Penggunaan dalam Aplikasi ===\n');

  // Setup recognizer (pada praktik, ini dilakukan di app.dart)
  final tfliteRecognizer = TfliteCurrencyRecognizer(
    modelAssetPath: 'assets/models/rupieye_float32.tflite',
    labelsAssetPath: 'assets/models/labels.txt',
  );

  final groqRecognizer = GroqCurrencyRecognizer(
    apiKey: 'your_groq_api_key',
  );

  final recognizer = TfliteGroqCurrencyRecognizer(
    tfliteRecognizer: tfliteRecognizer,
    groqRecognizer: groqRecognizer,
    enableLogging: true,
  );

  // Scenario 1: Gambar berhasil dikenali dengan TFLite
  print('Scenario 1: Pengenalan dengan TFLite (cepat)');
  print('---');
  try {
    final result = await recognizer.recognizeCurrency(
      imagePath: '/path/to/rupiah_100k.jpg',
    );
    print('✓ Hasil: ${result.formattedAmount} (${result.spokenText})');
    print('✓ Waktu: ~200ms (dari TFLite)\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Scenario 2: TFLite confidence rendah, fallback ke Groq
  print('Scenario 2: TFLite gagal → Groq AI (akurat)');
  print('---');
  try {
    final result = await recognizer.recognizeCurrency(
      imagePath: '/path/to/unclear_rupiah.jpg',
    );
    print('✓ TFLite confidence terlalu rendah');
    print('✓ Fallback ke Groq AI');
    print('✓ Hasil: ${result.formattedAmount} (${result.spokenText})');
    print('✓ Waktu: ~3 detik (dari Groq)\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Scenario 3: Kedua gagal
  print('Scenario 3: Kedua metode gagal');
  print('---');
  try {
    final result = await recognizer.recognizeCurrency(
      imagePath: '/path/to/not_rupiah.jpg', // bukan uang
    );
    print('✓ Hasil: ${result.formattedAmount}');
  } catch (e) {
    print('✗ Pengenalan gagal');
    print('✗ Penyebab: $e');
    print('✗ Solusi: Coba scan ulang dengan angle/pencahayaan berbeda\n');
  }
}

/// Tips penggunaan di Flutter Widget
void demonstrateInWidget() {
  print('=== Contoh 3: Penggunaan dalam Flutter Widget ===\n');

  print('''
// Di dalam State widget:

class _ScanPageState extends State<ScanPage> {
  late final CurrencyRecognizer _recognizer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Recognizer sudah di-setup di app.dart
    _recognizer = widget.recognizer;
  }

  Future<void> _processCapturedImage(String imagePath) async {
    setState(() => _isProcessing = true);
    
    try {
      // Panggil recognizer dengan gambar
      final result = await _recognizer.recognizeCurrency(
        imagePath: imagePath,
      );
      
      // Tampilkan hasil
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
              Text(result.spokenText),
            ],
          ),
        ),
      );
    } on CurrencyRecognitionException catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \${e.message}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
''');
}

/// Tips debugging dan monitoring
void demonstrateDebugging() {
  print('\n=== Tips Debugging ===\n');

  print('''
1. Aktifkan Logging:
   - Set enableLogging: true di TfliteGroqCurrencyRecognizer
   - Lihat log di debug console

2. Monitor API Usage:
   - Groq API free tier unlimited untuk vision
   - Cek usage di https://console.groq.com

3. Optimize untuk Performance:
   - TFLite: ~100-500ms (dominan untuk most cases)
   - Groq: ~2-5s (hanya jika TFLite gagal)
   - Set tfliteHighConfidenceThreshold lebih tinggi untuk skip Groq lebih sering

4. Error Handling:
   - "Groq API error (401)": API key salah
   - "Groq API error (429)": Rate limit exceeded
   - "Groq API error (403)": Akses ditolak
   - "Groq AI tidak menemukan nominal rupiah": Bukan uang/gambar buruk

5. Cek Koneksi Internet:
   - TFLite: Tidak perlu internet
   - Groq: Wajib internet
   - Dalam hybrid: Jika internet down, TFLite tetap jalan (baik!)
''');
}
