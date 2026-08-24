import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Opens [bytes] in a fullscreen, pinch-to-zoomable viewer with a fade
/// transition. Pass the same [heroTag] the thumbnail uses for a smooth
/// shared-element animation between the two.
Future<void> showFullscreenImage(
  BuildContext context,
  Uint8List bytes, {
  required String heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: _FullscreenImageViewer(bytes: bytes, heroTag: heroTag),
      ),
    ),
  );
}

class _FullscreenImageViewer extends StatelessWidget {
  final Uint8List bytes;
  final String heroTag;

  const _FullscreenImageViewer({required this.bytes, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
