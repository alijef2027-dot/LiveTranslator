import 'dart:async';

import 'package:flutter_overlay_window_plus/flutter_overlay_window_plus.dart';

/// Manages the system floating overlay lifecycle and the string pipe
/// between the main app isolate and the overlay isolate.
///
/// The overlay runs in a separate Flutter engine, so the two sides
/// communicate via [FlutterOverlayWindowPlus.shareData] (a bidirectional
/// string channel). We JSON-encode subtitle updates on this channel.
class OverlayService {
  StreamSubscription<dynamic>? _dataSub;

  /// Returns true if the user has granted the "display over other apps"
  /// permission.
  static Future<bool> hasOverlayPermission() async {
    return FlutterOverlayWindowPlus.isPermissionGranted();
  }

  /// Requests the SYSTEM_ALERT_WINDOW permission via the system settings page.
  static Future<void> requestOverlayPermission() async {
    await FlutterOverlayWindowPlus.requestPermission();
  }

  /// Shows the floating overlay window.
  Future<void> showOverlay() async {
    await FlutterOverlayWindowPlus.showOverlay(
      height: 180,
      width: 320,
      alignment: OverlayAlignment.bottom,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'VoiceBridge',
      overlayContent: 'Translation',
      enableDrag: true,
      positionGravity: PositionGravity.auto,
    );
  }

  /// Hides the overlay if currently visible.
  Future<void> hideOverlay() async {
    await FlutterOverlayWindowPlus.closeOverlay();
  }

  /// Sends a JSON-encoded subtitle payload to the overlay isolate.
  Future<void> pushSubtitle(String jsonPayload) async {
    await FlutterOverlayWindowPlus.shareData(jsonPayload);
  }

  /// Listens for messages coming back from the overlay isolate (e.g. the user
  /// tapped "stop" on the bubble). [onData] is called for every message.
  void listenToOverlay(void Function(dynamic data) onData) {
    _dataSub?.cancel();
    _dataSub = FlutterOverlayWindowPlus.overlayListener.listen(onData);
  }

  /// Stops listening to the overlay channel.
  void stopListening() {
    _dataSub?.cancel();
    _dataSub = null;
  }

  Future<void> dispose() async {
    stopListening();
  }
}
