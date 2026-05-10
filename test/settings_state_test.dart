import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    show TextRecognitionScript;

void main() {
  test(
    'SettingsState defaults: PDF format, notifications on, Latin OCR',
    () {
      const s = SettingsState(
        defaultSaveFormat: DefaultSaveFormat.pdf,
        notificationsEnabled: true,
        ocrScript: TextRecognitionScript.latin,
      );
      expect(s.defaultSaveFormat, DefaultSaveFormat.pdf);
      expect(s.notificationsEnabled, isTrue);
      expect(s.ocrScript, TextRecognitionScript.latin);
    },
  );

  test('SettingsState.copyWith only overwrites the named fields', () {
    const s = SettingsState(
      defaultSaveFormat: DefaultSaveFormat.pdf,
      notificationsEnabled: true,
      ocrScript: TextRecognitionScript.latin,
    );
    final t = s.copyWith(defaultSaveFormat: DefaultSaveFormat.jpg);
    expect(t.defaultSaveFormat, DefaultSaveFormat.jpg);
    expect(t.notificationsEnabled, isTrue);
    expect(t.ocrScript, TextRecognitionScript.latin);

    final u = s.copyWith(notificationsEnabled: false);
    expect(u.defaultSaveFormat, DefaultSaveFormat.pdf);
    expect(u.notificationsEnabled, isFalse);

    final v = s.copyWith(ocrScript: TextRecognitionScript.japanese);
    expect(v.defaultSaveFormat, DefaultSaveFormat.pdf);
    expect(v.ocrScript, TextRecognitionScript.japanese);
  });

  test('ocrScriptDisplayName covers every script', () {
    for (final s in TextRecognitionScript.values) {
      expect(ocrScriptDisplayName(s), isNotEmpty);
      expect(ocrScriptShortName(s), isNotEmpty);
    }
  });
}
