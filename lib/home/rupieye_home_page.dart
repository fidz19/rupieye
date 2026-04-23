import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rupieye/home/rupieye_scan_page.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/speech_service.dart';

const _homeInstructions =
    'Tekan bagian tengah layar untuk memulai scan, dan arahkan handphone anda ke uang. '
    'Rupi-eye akan mendeteksi nominal uang rupiah yang anda pindai. '
    'Tekan pojok kanan bawah layar untuk bantuan.';

class RupieyeHomePage extends StatefulWidget {
  const RupieyeHomePage({
    super.key,
    required this.recognizer,
    required this.speechService,
    required this.enableCamera,
  });

  final CurrencyRecognizer recognizer;
  final SpeechService speechService;
  final bool enableCamera;

  @override
  State<RupieyeHomePage> createState() => _RupieyeHomePageState();
}

class _RupieyeHomePageState extends State<RupieyeHomePage> {
  bool _isSpeakingInstructions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_speakInstructions());
    });
  }

  Future<void> _speakInstructions() async {
    if (_isSpeakingInstructions) {
      return;
    }

    _isSpeakingInstructions = true;
    try {
      await widget.speechService.speak(_homeInstructions);
    } finally {
      _isSpeakingInstructions = false;
    }
  }

  Future<void> _openScanPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RupieyeScanPage(
          recognizer: widget.recognizer,
          speechService: widget.speechService,
          enableCamera: widget.enableCamera,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    unawaited(_speakInstructions());
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF31378B);
    const brandBlueDark = Color(0xFF20275F);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 700;
              final logoSize = isCompact ? 96.0 : 138.0;
              final scanButtonSize = isCompact ? 214.0 : 270.0;
              final helpButtonSize = isCompact ? 92.0 : 108.0;
              final outerPadding = isCompact ? 20.0 : 28.0;
              final reservedBottom = isCompact ? 100.0 : 120.0;
              final scanIconSize = isCompact ? 60.0 : 78.0;

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        outerPadding,
                        outerPadding,
                        outerPadding,
                        reservedBottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              outerPadding -
                              reservedBottom,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 0 : 12),
                            Image.asset(
                              'assets/images/logo_rupi_eye.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: isCompact ? 12 : 18),
                            Text(
                              'RUPI-EYE',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: brandBlue,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    fontSize: isCompact ? 34 : null,
                                  ),
                            ),
                            SizedBox(height: isCompact ? 12 : 18),
                            Text(
                              'Aplikasi bantu untuk mengenali nominal uang rupiah dengan kamera dan suara.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: brandBlueDark,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isCompact ? 17 : null,
                                  ),
                            ),
                            SizedBox(height: isCompact ? 22 : 34),
                            Semantics(
                              button: true,
                              label:
                                  'Tekan bagian tengah layar untuk memulai scan',
                              child: SizedBox(
                                width: scanButtonSize,
                                height: scanButtonSize,
                                child: ElevatedButton(
                                  onPressed: _openScanPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 18,
                                    shadowColor: const Color(0x3020275F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 34 : 42,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(
                                      isCompact ? 20 : 28,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: scanIconSize,
                                      ),
                                      SizedBox(height: isCompact ? 12 : 18),
                                      Text(
                                        'SCAN',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                              fontSize: isCompact ? 32 : null,
                                            ),
                                      ),
                                      if (!isCompact) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tekan untuk masuk ke layar pemindaian uang rupiah',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFFE5E8FF),
                                                height: 1.35,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 12 : 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: isCompact ? 18 : 22,
                    bottom: isCompact ? 18 : 24,
                    child: Semantics(
                      button: true,
                      label:
                          'Tombol bantuan untuk mengulangi instruksi penggunaan',
                      child: SizedBox(
                        width: helpButtonSize,
                        height: helpButtonSize,
                        child: ElevatedButton(
                          onPressed: _speakInstructions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlueDark,
                            foregroundColor: Colors.white,
                            elevation: 16,
                            shadowColor: const Color(0x3820275F),
                            padding: EdgeInsets.all(isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isCompact ? 24 : 30,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.help_rounded,
                                size: isCompact ? 28 : 34,
                              ),
                              SizedBox(height: isCompact ? 4 : 6),
                              Text(
                                'HELP',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      fontSize: isCompact ? 16 : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
