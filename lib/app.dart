import 'package:flutter/material.dart';
import 'package:rupieye/home/rupieye_intro_screen.dart';
import 'package:rupieye/home/rupieye_home_page.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/speech_service.dart';
import 'package:rupieye/services/tflite_currency_recognizer.dart';

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
    _recognizer =
        widget._recognizer ??
        TfliteCurrencyRecognizer(
          modelAssetPath: 'assets/models/model_unquant_rupiah1.tflite',
          labelsAssetPath: 'assets/models/labels.txt',
        );
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
