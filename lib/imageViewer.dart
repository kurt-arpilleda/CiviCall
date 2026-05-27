import 'package:flutter/material.dart';

void showFullScreenImage(BuildContext context, ImageProvider imageProvider) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.95),
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}