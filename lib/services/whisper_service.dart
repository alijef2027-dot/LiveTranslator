import 'dart:async';

import 'package:whisper_cpp_flutter_plus/whisper_cpp_flutter_plus.dart';

/// Wraps the on-device Whisper engine for live English transcription.
///
/// Whisper's built-in `translate` flag only produces English from other
/// languages, so we transcribe English here and translate separately.
/// `threads: 4` is tuned for the MediaTek Helio G99: enough parallelism
/// for real-time decoding without sustained thermal load.
class WhisperService {
  WhisperEngine? _engine;
  WhisperModelManager? _modelManager;
  StreamSubscription<WhisperStreamUpdate>? _updateSub;
  WhisperStreamTask? _micTask;

  bool _isListening = false;
  bool get isListening => _isListening;
  bool get isModelLoaded => _engine != null;

  /// Loads the tiny English Whisper model. If it is not already cached,
  /// [downloadProgress] receives download fractions (0.0 - 1.0).
  Future<void> loadModel({
    void Function(double fraction)? downloadProgress,
  }) async {
    if (_engine != null) return;

    _modelManager = WhisperModelManager();
    final descriptor = WhisperModelCatalog.tinyEnglish;

    var model = await _modelManager!.findCatalogModel(descriptor);
    if (model == null) {
      await for (final progress
          in _modelManager!.downloadCatalogModel(descriptor)) {
        downloadProgress?.call(progress.fraction);
      }
      model = await _modelManager!.findCatalogModel(descriptor);
    }
    if (model == null) {
      throw StateError('Whisper model download failed.');
    }

    _engine = await WhisperEngine.load(model.path);
  }

  /// Starts live microphone transcription. [onUpdate] fires for every
  /// streaming update (provisional + confirmed text).
  Future<void> startListening({
    required void Function(String confirmedText, String partialText) onUpdate,
  }) async {
    if (_engine == null) {
      throw StateError('Whisper model not loaded. Call loadModel() first.');
    }
    if (_isListening) return;

    final task = await _engine!.transcribeMicrophone(
      options: const TranscribeOptions(
        language: 'en',
        translate: false,
        threads: 4,
        tokenTimestamps: false,
      ),
    );
    _micTask = task;
    _isListening = true;

    _updateSub = task.updates.listen((update) {
      onUpdate(update.confirmedText, update.partialText);
    });
  }

  /// Gracefully stops capture, flushes remaining audio, and returns the
  /// final confirmed transcript.
  Future<String> stopListening() async {
    if (!_isListening || _micTask == null) return '';

    _isListening = false;
    await _updateSub?.cancel();
    _updateSub = null;

    final complete = await _micTask!.stop();
    _micTask = null;
    return complete.confirmedText;
  }

  /// Cancels any active transcription without flushing.
  Future<void> cancel() async {
    _isListening = false;
    await _updateSub?.cancel();
    _updateSub = null;
    try {
      await _micTask?.cancel();
    } on WhisperException {
      // Expected when cancelling mid-stream.
    }
    _micTask = null;
  }

  /// Releases the engine and model manager. Safe to call multiple times.
  Future<void> dispose() async {
    await cancel();
    _engine?.dispose();
    _engine = null;
    _modelManager?.close();
    _modelManager = null;
  }
}
