import 'dart:async';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// On-device English -> Arabic translator backed by Google ML Kit.
///
/// The Arabic language model is downloaded once on first use and then all
/// translation runs fully offline. This complements Whisper, which can only
/// translate *to* English — ML Kit fills the EN -> AR gap locally.
class TranslationService {
  final OnDeviceTranslator _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.arabic,
  );

  bool _modelDownloaded = false;
  bool _downloading = false;

  bool get isModelDownloaded => _modelDownloaded;

  /// Ensures the Arabic model is available on-device. [onProgress] receives
  /// download percentages (0 - 100).
  Future<void> ensureModelDownloaded({
    void Function(int percentage)? onProgress,
  }) async {
    if (_modelDownloaded || _downloading) return;

    final manager = ModelManager();
    final downloaded = await manager.isModelDownloaded('ar');
    if (downloaded) {
      _modelDownloaded = true;
      return;
    }

    _downloading = true;
    final stream = manager.downloadModel('ar', isWifiRequired: false);
    await for (final event in stream) {
      if (event == DownloadEvent.success) {
        _modelDownloaded = true;
      }
      // Map event to a rough percentage for UI feedback.
      onProgress?.call(event == DownloadEvent.success ? 100 : 50);
    }
    _downloading = false;
  }

  /// Translates [text] from English to Arabic on-device. Returns the input
  /// unchanged if translation fails so the UI never shows empty.
  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return '';
    try {
      final result = await _translator.translateText(text);
      return result.trim();
    } on Exception {
      return text;
    }
  }

  Future<void> dispose() async {
    await _translator.close();
  }
}
