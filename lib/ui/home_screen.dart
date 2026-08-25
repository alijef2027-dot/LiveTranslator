import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/subtitle_state.dart';
import '../services/overlay_service.dart';
import '../services/translation_service.dart';
import '../services/whisper_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.whisperService,
    required this.translationService,
    required this.overlayService,
  });

  final WhisperService whisperService;
  final TranslationService translationService;
  final OverlayService overlayService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TranslationStatus _status = TranslationStatus.idle;
  String _statusMessage = 'Tap Start to begin.';
  double _modelProgress = 0.0;
  bool _modelDownloading = false;

  String _confirmedEnglish = '';
  String _provisionalEnglish = '';
  String _latestArabic = '';

  @override
  void initState() {
    super.initState();
    // Listen for messages from the overlay (e.g. user tapped stop on bubble).
    widget.overlayService.listenToOverlay(_onOverlayMessage);
  }

  @override
  void dispose() {
    _stopPipeline();
    widget.overlayService.dispose();
    widget.whisperService.dispose();
    widget.translationService.dispose();
    super.dispose();
  }

  void _onOverlayMessage(String data) {
    if (data == 'stop') {
      _stopPipeline();
    }
  }

  Future<void> _startPipeline() async {
    // 1. Permissions: microphone + overlay.
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _setStatus(TranslationStatus.error, 'Microphone permission denied.');
      return;
    }
    final overlayGranted = await OverlayService.hasOverlayPermission();
    if (!overlayGranted) {
      await OverlayService.requestOverlayPermission();
      final recheck = await OverlayService.hasOverlayPermission();
      if (!recheck) {
        _setStatus(TranslationStatus.error,
            'Overlay permission denied. Enable "Display over other apps".');
        return;
      }
    }

    setState(() {
      _status = TranslationStatus.loadingModel;
      _statusMessage = 'Preparing offline models...';
      _modelDownloading = true;
      _modelProgress = 0.0;
    });

    try {
      await widget.whisperService.loadModel(
        downloadProgress: (fraction) {
          setState(() => _modelProgress = fraction);
        },
      );
      await widget.translationService.ensureModelDownloaded();
    } on Exception catch (e) {
      _setStatus(TranslationStatus.error, 'Model setup failed: $e');
      return;
    } finally {
      setState(() => _modelDownloading = false);
    }

    // 2. Show the floating overlay.
    await widget.overlayService.showOverlay();

    // 3. Start live transcription + translation.
    setState(() {
      _status = TranslationStatus.listening;
      _statusMessage = 'Listening... Speak in English.';
    });

    await widget.whisperService.startListening(
      onUpdate: _onWhisperUpdate,
    );
  }

  Future<void> _onWhisperUpdate(
      String confirmedText, String provisionalText) async {
    setState(() {
      _confirmedEnglish = confirmedText;
      _provisionalEnglish = provisionalText;
    });

    // Translate the latest confirmed English text to Arabic and push to overlay.
    final arabic = await widget.translationService.translate(confirmedText);
    if (!mounted) return;

    setState(() => _latestArabic = arabic);

    // Send the Arabic subtitle to the overlay isolate via the string pipe.
    final payload = jsonEncode({
      'arabic': arabic,
      'english': confirmedText,
      'provisional': provisionalText,
    });
    await widget.overlayService.pushSubtitle(payload);
  }

  Future<void> _stopPipeline() async {
    await widget.whisperService.stopListening();
    await widget.overlayService.hideOverlay();
    if (!mounted) return;
    setState(() {
      _status = TranslationStatus.idle;
      _statusMessage = 'Stopped. Tap Start to begin again.';
      _confirmedEnglish = '';
      _provisionalEnglish = '';
    });
  }

  void _setStatus(TranslationStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _statusMessage = message;
    });
  }

  bool get _isListening => _status == TranslationStatus.listening;
  bool get _isBusy =>
      _status == TranslationStatus.loadingModel || _modelDownloading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 32),
              _statusCard(),
              const Spacer(),
              if (_latestArabic.isNotEmpty) _subtitlePreview(),
              const SizedBox(height: 24),
              _actionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.samsungBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'OFFLINE',
            style: TextStyle(
              color: AppTheme.samsungBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('VoiceBridge', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Live English speech translated to Arabic on your device. A floating '
          'subtitle appears over any app or video.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusDot(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (_modelDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _modelProgress,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.samsungBlue),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading Whisper model ${(_modelProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusDot() {
    final color = switch (_status) {
      TranslationStatus.listening => AppTheme.success,
      TranslationStatus.loadingModel => AppTheme.warning,
      TranslationStatus.error => AppTheme.error,
      _ => AppTheme.onSurfaceMuted,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: _isListening
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _subtitlePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Latest translation',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _latestArabic,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.arabicFontFamily,
                  height: 1.4,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _confirmedEnglish,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton() {
    final isListening = _isListening;
    return FilledButton.icon(
      onPressed: _isBusy ? null : (isListening ? _stopPipeline : _startPipeline),
      icon: Icon(isListening ? Icons.stop_rounded : Icons.mic_rounded),
      label: Text(isListening ? 'Stop' : 'Start Translation'),
      style: FilledButton.styleFrom(
        backgroundColor: isListening
            ? AppTheme.error
            : AppTheme.samsungBlue,
      ),
    );
  }
}
