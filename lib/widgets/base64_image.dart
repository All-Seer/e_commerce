import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Renders an image from a base64 data URL or raw base64 string.
class Base64Image extends StatelessWidget {
  final String base64;
  final BoxFit fit;
  final double? width;
  final double? height;

  const Base64Image({
    super.key,
    required this.base64,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (base64.isEmpty) return _placeholder();
    try {
      final data = base64.contains(',') ? base64.split(',').last : base64;
      final bytes = base64Decode(data);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppTheme.surface,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppTheme.textSecondary),
        ),
      );
}
