import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    show TextRecognitionScript;
import 'package:shared_preferences/shared_preferences.dart';

const _saveFormatKey = 'docscan.defaultSaveFormat';
const _notificationsKey = 'docscan.notificationsEnabled';
const _ocrScriptKey = 'docscan.ocrScript';

enum DefaultSaveFormat { pdf, jpg }

class SettingsState {
  const SettingsState({
    required this.defaultSaveFormat,
    required this.notificationsEnabled,
    required this.ocrScript,
  });

  final DefaultSaveFormat defaultSaveFormat;
  final bool notificationsEnabled;

  /// Primary script the OCR engine targets. Latin covers most European
  /// languages; the others are separate ML Kit models that have to be
  /// chosen explicitly.
  final TextRecognitionScript ocrScript;

  SettingsState copyWith({
    DefaultSaveFormat? defaultSaveFormat,
    bool? notificationsEnabled,
    TextRecognitionScript? ocrScript,
  }) =>
      SettingsState(
        defaultSaveFormat: defaultSaveFormat ?? this.defaultSaveFormat,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
        ocrScript: ocrScript ?? this.ocrScript,
      );
}

class SettingsController extends Notifier<SettingsState> {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    Future.microtask(_load);
    return const SettingsState(
      defaultSaveFormat: DefaultSaveFormat.pdf,
      notificationsEnabled: true,
      ocrScript: TextRecognitionScript.latin,
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await _ensurePrefs();
    final fmtRaw = prefs.getString(_saveFormatKey) ?? 'pdf';
    final notifs = prefs.getBool(_notificationsKey) ?? true;
    final scriptRaw = prefs.getString(_ocrScriptKey) ?? 'latin';
    state = SettingsState(
      defaultSaveFormat: fmtRaw == 'jpg'
          ? DefaultSaveFormat.jpg
          : DefaultSaveFormat.pdf,
      notificationsEnabled: notifs,
      ocrScript: _scriptFromKey(scriptRaw),
    );
  }

  Future<void> setDefaultSaveFormat(DefaultSaveFormat fmt) async {
    state = state.copyWith(defaultSaveFormat: fmt);
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _saveFormatKey,
      fmt == DefaultSaveFormat.jpg ? 'jpg' : 'pdf',
    );
  }

  Future<void> setNotifications({required bool enabled}) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await _ensurePrefs();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setOcrScript(TextRecognitionScript script) async {
    state = state.copyWith(ocrScript: script);
    final prefs = await _ensurePrefs();
    await prefs.setString(_ocrScriptKey, _keyForScript(script));
  }
}

String _keyForScript(TextRecognitionScript s) => switch (s) {
      TextRecognitionScript.latin => 'latin',
      TextRecognitionScript.chinese => 'chinese',
      TextRecognitionScript.devanagiri => 'devanagari',
      TextRecognitionScript.japanese => 'japanese',
      TextRecognitionScript.korean => 'korean',
    };

TextRecognitionScript _scriptFromKey(String k) => switch (k) {
      'chinese' => TextRecognitionScript.chinese,
      'devanagari' => TextRecognitionScript.devanagiri,
      'japanese' => TextRecognitionScript.japanese,
      'korean' => TextRecognitionScript.korean,
      _ => TextRecognitionScript.latin,
    };

String ocrScriptDisplayName(TextRecognitionScript s) => switch (s) {
      TextRecognitionScript.latin => 'Latin (English, Spanish, …)',
      TextRecognitionScript.chinese => 'Chinese',
      TextRecognitionScript.devanagiri => 'Devanagari (Hindi, …)',
      TextRecognitionScript.japanese => 'Japanese',
      TextRecognitionScript.korean => 'Korean',
    };

String ocrScriptShortName(TextRecognitionScript s) => switch (s) {
      TextRecognitionScript.latin => 'Latin',
      TextRecognitionScript.chinese => 'Chinese',
      TextRecognitionScript.devanagiri => 'Devanagari',
      TextRecognitionScript.japanese => 'Japanese',
      TextRecognitionScript.korean => 'Korean',
    };

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
