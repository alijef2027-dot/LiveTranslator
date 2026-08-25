# VoiceBridge

Live **offline** English-to-Arabic speech-to-text translation with a system
floating overlay, built for Android and tuned for the MediaTek Helio G99
(Samsung Galaxy A24).

Everything runs on-device:

- **Speech-to-text** — `whisper_cpp_flutter_plus` (whisper.cpp v1.9.2) transcribes
  English audio locally using the tiny English model and 4 CPU threads.
- **Translation** — `google_mlkit_translation` translates the English text to
  Arabic fully offline after the Arabic language model is downloaded once.
- **Floating overlay** — `flutter_overlay_window_plus` renders a translucent
  One UI-style subtitle bubble over other apps and video players.

> Whisper's built-in `translate` flag only translates *to English*, so it
> cannot produce Arabic. VoiceBridge instead transcribes English with Whisper,
> then translates EN→AR with ML Kit's on-device translator.

## Setup

1. `flutter pub get`
2. Place a Whisper model file at `assets/models/ggml-tiny.en.bin` (or let the
   app download it on first launch). The tiny English model (~75 MB) is
   recommended for real-time performance on the Helio G99.
3. `flutter run --release` on a connected Android device.

## Permissions

The app requests at runtime:

- `RECORD_AUDIO` — microphone capture for transcription.
- `SYSTEM_ALERT_WINDOW` — drawing the floating overlay over other apps.
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE` — keeping capture alive
  in the background while the overlay is visible.

## Architecture

```
lib/
  main.dart                 # App entry, permission flow, model download UI
  overlay_main.dart         # @pragma("vm:entry-point") overlay entry point
  services/
    whisper_service.dart    # Whisper engine load + live mic transcription
    translation_service.dart# ML Kit on-device EN -> AR translator
    overlay_service.dart    # Overlay show/hide + shareData bridge
  ui/
    home_screen.dart        # One UI dark home (start/stop, status, model DL)
    overlay_subtitle.dart   # The floating subtitle widget (RTL Arabic)
  theme/
    app_theme.dart          # Colors, type, shapes (One UI 8.5 dark)
  models/
    subtitle_state.dart     # Shared state model
```

## Notes

- The overlay and main app run in **separate isolates**; they communicate via
  `FlutterOverlayWindowPlus.shareData` (a platform-channel string pipe).
- Audio and translation streams use `StreamSubscription` and are cancelled in
  `dispose()` to prevent leaks.
- `cpuThreads: 4` keeps the SoC responsive without sustained thermal load.
