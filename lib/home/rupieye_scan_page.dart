import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/speech_service.dart';

enum ScanStatus { idle, capturing, recognizing, speaking, error }

class RupieyeScanPage extends StatefulWidget {
  const RupieyeScanPage({
    super.key,
    required this.recognizer,
    required this.speechService,
    required this.enableCamera,
  });

  final CurrencyRecognizer recognizer;
  final SpeechService speechService;
  final bool enableCamera;

  @override
  State<RupieyeScanPage> createState() => _RupieyeScanPageState();
}

class _RupieyeScanPageState extends State<RupieyeScanPage>
    with WidgetsBindingObserver {
  ScanStatus _status = ScanStatus.idle;
  CurrencyRecognition? _lastRecognition;
  String? _errorMessage;
  CameraController? _cameraController;
  bool _isInitializingCamera = false;
  String? _cameraMessage;
  String? _lastCapturedImagePath;

  bool get _isBusy => _status != ScanStatus.idle && _status != ScanStatus.error;
  bool get _hasReadyCamera =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enableCamera) {
      unawaited(_initializeCamera());
    } else {
      _cameraMessage = 'Mode test tanpa camera';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera(updateState: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (!widget.enableCamera ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCamera());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(
        _initializeCamera(preferredDescription: controller.description),
      );
    }
  }

  Future<void> _startScan() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _status = ScanStatus.capturing;
      _errorMessage = null;
    });

    try {
      String? imagePath;

      if (widget.enableCamera) {
        if (!_hasReadyCamera) {
          await _initializeCamera();
        }

        if (!_hasReadyCamera) {
          throw Exception(
            _cameraMessage ??
                'Camera belum siap. Pastikan izin camera sudah diberikan.',
          );
        }

        imagePath = await _captureImage();
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _status = ScanStatus.recognizing;
      });

      final recognition = await widget.recognizer.recognizeCurrency(
        imagePath: imagePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastRecognition = recognition;
        _status = ScanStatus.speaking;
      });

      await _performSuccessHaptic();
      await widget.speechService.speak(recognition.spokenText);

      if (!mounted) {
        return;
      }

      setState(() {
        _status = ScanStatus.idle;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = ScanStatus.error;
        _errorMessage = error.toString();
      });

      await _performFailureHaptic();
      await widget.speechService.speak('Pemindaian gagal. Silakan coba lagi.');
    }
  }

  Future<void> _performFailureHaptic() async {
    await _safeHaptic(HapticFeedback.heavyImpact);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _safeHaptic(HapticFeedback.heavyImpact);
  }

  Future<void> _performSuccessHaptic() async {
    await _safeHaptic(HapticFeedback.mediumImpact);
  }

  Future<void> _safeHaptic(Future<void> Function() callback) async {
    try {
      await callback();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _initializeCamera({
    CameraDescription? preferredDescription,
  }) async {
    if (!widget.enableCamera || _isInitializingCamera) {
      return;
    }

    _isInitializingCamera = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setCameraUnavailable('Camera tidak ditemukan pada perangkat ini.');
        return;
      }

      final description =
          preferredDescription ??
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      final previousController = _cameraController;
      _cameraController = controller;
      _cameraMessage = 'Camera aktif';
      await previousController?.dispose();

      if (!mounted) {
        return;
      }

      setState(() {});
    } on CameraException catch (error) {
      _setCameraUnavailable(_mapCameraException(error));
    } on MissingPluginException {
      _setCameraUnavailable(
        'Plugin camera belum tersedia di platform ini. Jalankan di Android atau iPhone.',
      );
    } catch (error) {
      _setCameraUnavailable('Gagal menyalakan camera: $error');
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<void> _disposeCamera({bool updateState = true}) async {
    final controller = _cameraController;
    _cameraController = null;

    if (updateState && mounted) {
      setState(() {});
    }

    await controller?.dispose();
  }

  Future<String?> _captureImage() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    if (controller.value.isTakingPicture) {
      return _lastCapturedImagePath;
    }

    final image = await controller.takePicture();
    _lastCapturedImagePath = image.path;
    return image.path;
  }

  void _setCameraUnavailable(String message) {
    _cameraMessage = message;

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  String _mapCameraException(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Akses camera ditolak. Izinkan camera agar RUPI-EYE bisa memindai uang.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Akses camera sebelumnya sudah ditolak. Aktifkan lagi lewat Settings.';
      case 'CameraAccessRestricted':
        return 'Akses camera dibatasi oleh perangkat.';
      default:
        return 'Camera error: ${error.description ?? error.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF31378B);

    return Scaffold(
      body: Semantics(
        button: true,
        enabled: !_isBusy,
        label: 'Tap layar untuk memulai pemindaian uang',
        child: InkWell(
          onTap: _startScan,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildPreviewBackground()),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xB3161B48),
                          const Color(0x00000000),
                          const Color(0x8A11152F),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  right: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_rupi_eye.png',
                        width: 52,
                        height: 52,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'RUPI-EYE',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              shadows: const [
                                Shadow(
                                  color: Color(0x80000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 26,
                  right: 26,
                  child: Center(
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x5A1F2338),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _resultTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _resultSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 118,
                  child: Text(
                    _bottomInstruction,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 76,
                  child: Text(
                    _cameraCaption,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 18,
                  child: Semantics(
                    button: true,
                    label: 'Kembali ke layar utama',
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(126, 58),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBackground() {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      final previewSize = controller.value.previewSize;
      if (previewSize != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        );
      }

      return CameraPreview(controller);
    }

    return Image.asset(
      'assets/images/reference_home.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) {
        return Container(color: const Color(0xFFC9CCD7));
      },
    );
  }

  String get _resultTitle {
    if (_lastRecognition != null &&
        (_status == ScanStatus.idle || _status == ScanStatus.speaking)) {
      return _lastRecognition!.formattedAmount.replaceFirst('Rp', '');
    }

    switch (_status) {
      case ScanStatus.idle:
        return 'SIAP';
      case ScanStatus.capturing:
        return 'SCAN';
      case ScanStatus.recognizing:
        return '...';
      case ScanStatus.speaking:
        return _lastRecognition?.formattedAmount.replaceFirst('Rp', '') ??
            '...';
      case ScanStatus.error:
        return 'GAGAL';
    }
  }

  String get _resultSubtitle {
    switch (_status) {
      case ScanStatus.idle:
        return _lastRecognition == null ? 'TAP UNTUK MEMINDAI' : 'TERDETEKSI';
      case ScanStatus.capturing:
        return 'MENGAMBIL GAMBAR';
      case ScanStatus.recognizing:
        return 'MENDETEKSI NOMINAL';
      case ScanStatus.speaking:
        return 'TERDETEKSI';
      case ScanStatus.error:
        return 'COBA LAGI';
    }
  }

  String get _bottomInstruction {
    if (_isBusy) {
      return 'Mohon Tunggu\nSedang Memindai';
    }

    if (_status == ScanStatus.error) {
      return 'Pemindaian Gagal\nTap Layar Untuk Mencoba Lagi';
    }

    return 'Tap Dimanapun Pada Layar\nUntuk Memulai Scan';
  }

  String get _cameraCaption {
    if (_status == ScanStatus.error && _errorMessage != null) {
      return _errorMessage!;
    }

    if (_hasReadyCamera) {
      return 'Camera handphone aktif';
    }

    return _cameraMessage ??
        'Menyiapkan camera. Jika diminta, izinkan akses camera.';
  }
}
