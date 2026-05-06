import 'package:flutter/material.dart';

/// Ouvre une image réseau dans un visualiseur plein écran avec zoom.
Future<void> showNetworkImageViewer(
  BuildContext context, {
  required String imageUrl,
  String? heroTag,
}) {
  final trimmedUrl = imageUrl.trim();
  if (trimmedUrl.isEmpty) {
    return Future.value();
  }

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      final image = Image.network(
        trimmedUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_outlined,
          size: 56,
          color: Colors.white70,
        ),
      );

      return Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.92),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: heroTag == null
                          ? image
                          : Hero(tag: heroTag, child: image),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 16,
              end: 16,
              child: SafeArea(
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
