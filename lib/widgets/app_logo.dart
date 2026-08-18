import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width = 200,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.asset(
        'assets/images/sudacard_logo.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback 1: Attempt the JPG path in case of decoder strictness
          return Image.asset(
            'assets/images/sudacard_logo.jpg',
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // Fallback 2: Attempt the overwritten old asset path in case of hot-reload cache
              return Image.asset(
                'assets/images/249bank.12.jpg',
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: width,
                    height: height ?? (width * 0.4),
                    color: Colors.grey[800],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
