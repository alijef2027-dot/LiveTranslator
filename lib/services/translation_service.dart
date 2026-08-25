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

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  bool _modelDownloaded = false;
  bool _downloading = false;

  bool get isModelDownloaded => _modelDownloaded;

  /// Ensures the Arabic model is available on-device. [onProgress] receives
  /// a coarse percentage (0 - 100) for UI feedback.
  Future<void> ensureModelDownloaded({
    void Function(int percentage)? onProgress,
  }) async {
    if (_modelDownloaded || _downloading) return;

    final downloaded =
        await _modelManager.isModelDownloaded(TranslateLanguage.arabic.bcpCode);
    if (downloaded) {
      _modelDownloaded = true;
      return;
    }

    _downloading = true;
    onProgress?.call(0);
    final success =
        await _modelManager.downloadModel(TranslateLanguage.arabic.bcpCode);
    if (success) {
      _modelDownloaded = true;
      onProgress?.call(100);
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
