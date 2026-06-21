import 'package:flutter/material.dart';
import 'package:rupieye/home/rupieye_intro_screen.dart';
import 'package:rupieye/home/rupieye_home_page.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/groq_currency_recognizer.dart';
import 'package:rupieye/services/hybrid_currency_recognizer.dart';
import 'package:rupieye/services/online_currency_recognizer.dart';
import 'package:rupieye/services/roboflow_currency_recognizer.dart';
import 'package:rupieye/services/speech_service.dart';
import 'package:rupieye/services/tflite_currency_recognizer.dart';
import 'package:rupieye/services/tflite_groq_currency_recognizer.dart';

const _onlineRecognizerUrl = String.fromEnvironment(
  'RUPIEYE_ONLINE_RECOGNIZER_URL',
);
const _roboflowApiUrl = String.fromEnvironment(
  'RUPIEYE_ROBOFLOW_API_URL',
  defaultValue: 'https://serverless.roboflow.com',
);
const _roboflowApiKey = String.fromEnvironment('RUPIEYE_ROBOFLOW_API_KEY');
const _roboflowModelId = String.fromEnvironment(
  'RUPIEYE_ROBOFLOW_MODEL_ID',
  defaultValue: 'deteksi-rupiah/3',
);
const _groqApiKey = String.fromEnvironment('RUPIEYE_GROQ_API_KEY');

class RupieyeApp extends StatefulWidget {
  const RupieyeApp({
    super.key,
    CurrencyRecognizer? recognizer,
    SpeechService? speechService,
    bool showIntro = true,
    bool enableCamera = true,
  }) : _recognizer = recognizer,
       _speechService = speechService,
       _showIntro = showIntro,
       _enableCamera = enableCamera;

  final CurrencyRecognizer? _recognizer;
  final SpeechService? _speechService;
  final bool _showIntro;
  final bool _enableCamera;

  @override
  State<RupieyeApp> createState() => _RupieyeAppState();
}

class _RupieyeAppState extends State<RupieyeApp> {
  bool _introFinished = false;
  late final CurrencyRecognizer _recognizer;
  late final SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _recognizer = widget._recognizer ?? _createDefaultRecognizer();
    _speechService = widget._speechService ?? FlutterTtsSpeechService();

    if (!widget._showIntro) {
      _introFinished = true;
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _introFinished = true;
      });
    });
  }

  CurrencyRecognizer _createDefaultRecognizer() {
    final offlineRecognizer = TfliteCurrencyRecognizer(
      modelAssetPath: 'assets/models/rupieye_float32.tflite',
      labelsAssetPath: 'assets/models/labels.txt',
    );

    // Prioritas 1: TFLite + Groq AI Hybrid
    if (_groqApiKey.isNotEmpty) {
      final groqRecognizer = GroqCurrencyRecognizer(
        apiKey: _groqApiKey,
      );
      return TfliteGroqCurrencyRecognizer(
        tfliteRecognizer: offlineRecognizer,
        groqRecognizer: groqRecognizer,
        enableLogging: true,
      );
    }

    // Prioritas 2: TFLite + Roboflow Hybrid
    if (_roboflowApiKey.isNotEmpty) {
      return HybridCurrencyRecognizer(
        offlineRecognizer: offlineRecognizer,
        onlineRecognizer: RoboflowCurrencyRecognizer(
          apiUrl: _roboflowApiUrl,
          apiKey: _roboflowApiKey,
          modelId: _roboflowModelId,
        ),
      );
    }

    // Prioritas 3: TFLite + Custom Online Recognizer
    if (_onlineRecognizerUrl.isNotEmpty) {
      final endpoint = Uri.tryParse(_onlineRecognizerUrl);
      if (endpoint != null && endpoint.hasScheme && endpoint.host.isNotEmpty) {
        return HybridCurrencyRecognizer(
          offlineRecognizer: offlineRecognizer,
          onlineRecognizer: OnlineCurrencyRecognizer(endpoint: endpoint),
        );
      }
    }

    // Fallback: TFLite saja
    return offlineRecognizer;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUPI-EYE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F347D),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _introFinished
            ? RupieyeHomePage(
                recognizer: _recognizer,
                speechService: _speechService,
                enableCamera: widget._enableCamera,
              )
            : const RupieyeIntroScreen(),
      ),
    );
  }
}
