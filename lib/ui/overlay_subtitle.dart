import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window_plus/flutter_overlay_window_plus.dart';

import '../theme/app_theme.dart';

/// Root widget for the overlay isolate. Listens for subtitle payloads sent
/// from the main app via [FlutterOverlayWindowPlus.shareData] and renders
/// the One UI-style translucent subtitle bubble.
class OverlaySubtitleApp extends StatelessWidget {
  const OverlaySubtitleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlaySubtitleScreen(),
    );
  }
}

class OverlaySubtitleScreen extends StatefulWidget {
  const OverlaySubtitleScreen({super.key});

  @override
  State<OverlaySubtitleScreen> createState() => _OverlaySubtitleScreenState();
}

class _OverlaySubtitleScreenState extends State<OverlaySubtitleScreen> {
  String _arabic = '';
  String _provisional = '';
  StreamSubscription<dynamic>? _dataSub;

  @override
  void initState() {
    super.initState();
    _dataSub = FlutterOverlayWindowPlus.overlayListener.listen(_onData);
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }

  void _onData(dynamic payload) {
    try {
      final map = jsonDecode(payload as String) as Map<String, dynamic>;
      setState(() {
        _arabic = (map['arabic'] as String?) ?? '';
        _provisional = (map['provisional'] as String?) ?? '';
      });
    } on FormatException {
      // Ignore malformed payloads.
    }
  }

  Future<void> _stop() async {
    await FlutterOverlayWindowPlus.shareData('stop');
    await FlutterOverlayWindowPlus.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _stop,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.overlayRadius),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: AppTheme.overlayBlurSigma,
              sigmaY: AppTheme.overlayBlurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.overlaySurface
                    .withOpacity(AppTheme.overlayOpacity),
                borderRadius:
                    BorderRadius.circular(AppTheme.overlayRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_arabic.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _arabic,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.arabicFontFamily,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  if (_provisional.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _provisional,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppTheme.arabicFontFamily,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                  if (_arabic.isEmpty && _provisional.isEmpty)
                    Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
