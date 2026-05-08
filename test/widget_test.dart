import 'package:flutter_test/flutter_test.dart';
import 'package:rupieye/app.dart';
import 'package:rupieye/home/rupieye_scan_page.dart';
import 'package:rupieye/models/currency_recognition.dart';
import 'package:rupieye/services/currency_recognizer.dart';
import 'package:rupieye/services/speech_service.dart';

void main() {
  testWidgets('navigates from home to scan page and shows recognition result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RupieyeApp(
        recognizer: _FakeRecognizer(),
        speechService: SilentSpeechService(),
        showIntro: false,
        enableCamera: false,
      ),
    );

    expect(find.text('RUPI-EYE'), findsOneWidget);
    expect(find.text('SCAN'), findsOneWidget);
    expect(find.text('HELP'), findsOneWidget);

    await tester.tap(find.text('SCAN'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(RupieyeScanPage), findsOneWidget);
    expect(find.text('TAP UNTUK MEMINDAI'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(RupieyeScanPage)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();

    expect(find.text('MENDETEKSI NOMINAL'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1050));
    await tester.pump();

    expect(find.text('20.000'), findsOneWidget);
    expect(find.text('TERDETEKSI'), findsOneWidget);
  });
}

class _FakeRecognizer implements CurrencyRecognizer {
  @override
  Future<CurrencyRecognition> recognizeCurrency({String? imagePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    return CurrencyRecognition(amount: 20000);
  }
}
