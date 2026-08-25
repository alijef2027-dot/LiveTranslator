import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/overlay_subtitle.dart';

/// Top-level entry point for the overlay isolate. Must be a standalone
/// top-level function annotated with @pragma("vm:entry-point") so the
/// Flutter toolchain retains it for the overlay engine.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait so the bubble doesn't rebuild on rotation while visible.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const OverlaySubtitleApp());
}
