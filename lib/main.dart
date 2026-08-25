import 'package:flutter/material.dart';

import 'services/overlay_service.dart';
import 'services/translation_service.dart';
import 'services/whisper_service.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceBridgeApp());
}

class VoiceBridgeApp extends StatelessWidget {
  const VoiceBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: HomeScreen(
        whisperService: WhisperService(),
        translationService: TranslationService(),
        overlayService: OverlayService(),
      ),
    );
  }
}
