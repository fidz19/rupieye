import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechService {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> stop();
  void dispose();
}

class FlutterTtsSpeechService implements SpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isAvailable = true;

  @override
  Future<void> initialize() async {
    if (_isInitialized || !_isAvailable) {
      return;
    }

    await _tryInvoke(
      () => _flutterTts.awaitSpeakCompletion(true),
      action: 'awaitSpeakCompletion',
      disableOnPlatformException: false,
    );
    await _configureLanguage();
    await _tryInvoke(
      () => _flutterTts.setSpeechRate(0.45),
      action: 'setSpeechRate',
      disableOnPlatformException: false,
    );
    await _tryInvoke(
      () => _flutterTts.setPitch(1.0),
      action: 'setPitch',
      disableOnPlatformException: false,
    );
    await _tryInvoke(
      () => _flutterTts.setVolume(1.0),
      action: 'setVolume',
      disableOnPlatformException: false,
    );

    if (_isAvailable) {
      _isInitialized = true;
    }
  }

  @override
  Future<void> speak(String text) async {
    await initialize();
    if (!_isAvailable) {
      return;
    }

    await _tryInvoke(() => _flutterTts.stop(), action: 'stop');
    await _tryInvoke(() => _flutterTts.speak(text), action: 'speak');
  }

  @override
  Future<void> stop() async {
    if (!_isAvailable) {
      return;
    }

    await _tryInvoke(() => _flutterTts.stop(), action: 'stop');
  }

  @override
  void dispose() {}

  Future<void> _tryInvoke(
    Future<dynamic> Function() callback, {
    required String action,
    bool disableOnPlatformException = true,
  }) async {
    if (!_isAvailable) {
      return;
    }

    try {
      await callback();
    } on MissingPluginException catch (error) {
      _disableTts('TTS plugin is not available for action "$action": $error');
    } on PlatformException catch (error) {
      final message =
          'TTS platform call failed for action "$action": ${error.code} ${error.message ?? ''}'
              .trim();
      if (disableOnPlatformException) {
        _disableTts(message);
      } else {
        debugPrint(message);
      }
    }
  }

  void _disableTts(String message) {
    _isAvailable = false;
    debugPrint(message);
  }

  Future<void> _configureLanguage() async {
    const candidates = <String>['id-ID', 'id', 'en-US'];

    for (final language in candidates) {
      if (!_isAvailable) {
        return;
      }

      try {
        await _flutterTts.setLanguage(language);
        debugPrint('TTS language set to $language');
        return;
      } on PlatformException catch (error) {
        debugPrint(
          'TTS language "$language" unavailable: ${error.code} ${error.message ?? ''}'
              .trim(),
        );
      } on MissingPluginException catch (error) {
        _disableTts(
          'TTS plugin is not available for action "setLanguage": $error',
        );
        return;
      }
    }

    debugPrint(
      'No preferred TTS language was available. Continuing with device default voice if possible.',
    );
  }
}

class SilentSpeechService implements SpeechService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
