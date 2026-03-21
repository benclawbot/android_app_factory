import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Generates Android launcher icons from app name initials.
///
/// Creates a PNG icon at multiple densities (mdpi → xxxhdpi) and writes
/// them into the standard `res/mipmap-*` directories.
class IconGenerator {
  IconGenerator._();

  // Android mipmap densities → pixel sizes
  static const _densities = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  /// Derives 1-2 letter initials from [appName].
  ///
  /// "Recipe Book" → "RB", "MyApp" → "MA", "X" → "X"
  static String initials(String appName) {
    final words = appName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    final name = words.first;
    // Try camelCase split: "MyApp" → "MA"
    final caps = name.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).toList();
    if (caps.length >= 2) return '${caps[0]}${caps[1]}';
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  /// Picks a deterministic accent color based on the app name hash.
  static Color accentColorFor(String appName) {
    const palette = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFFEAB308), // Yellow
      Color(0xFF22C55E), // Green
      Color(0xFF14B8A6), // Teal
      Color(0xFF06B6D4), // Cyan
      Color(0xFF3B82F6), // Blue
    ];
    final hash = appName.codeUnits.fold<int>(0, (h, c) => h * 31 + c);
    return palette[hash.abs() % palette.length];
  }

  /// Renders a square icon as PNG bytes at the given [size].
  ///
  /// The icon is a filled rounded-rectangle with the app's accent color
  /// and white initials centered on it.
  static Future<Uint8List> renderIcon({
    required String appName,
    required int size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    final bgColor = accentColorFor(appName);
    final s = size.toDouble();

    // Background rounded rect (slight radius for a modern look)
    final bgPaint = Paint()..color = bgColor;
    final radius = s * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(radius),
      ),
      bgPaint,
    );

    // Initials text
    final letters = initials(appName);
    final fontSize = s * (letters.length > 1 ? 0.38 : 0.48);
    final textStyle = ui.TextStyle(
      color: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    )
      ..pushStyle(textStyle)
      ..addText(letters);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: s));

    // Center vertically
    final textHeight = paragraph.height;
    final yOffset = (s - textHeight) / 2;
    canvas.drawParagraph(paragraph, Offset(0, yOffset));

    // Encode to PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Writes launcher icons into the standard Android mipmap directories.
  ///
  /// If [customIconPath] is provided and the file exists, it resizes that
  /// image instead of generating from initials. Otherwise it auto-generates.
  ///
  /// Returns the list of relative paths written (for the file manifest).
  static Future<Map<String, Uint8List>> generateMipmapIcons({
    required String appName,
    String? customIconPath,
  }) async {
    final icons = <String, Uint8List>{};

    Uint8List? customBytes;
    if (customIconPath != null && File(customIconPath).existsSync()) {
      customBytes = await File(customIconPath).readAsBytes();
    }

    for (final entry in _densities.entries) {
      final density = entry.key;
      final size = entry.value;
      final relativePath = 'app/src/main/res/$density/ic_launcher.png';

      if (customBytes != null) {
        // Resize the custom icon to the target density
        final resized = await _resizeImage(customBytes, size);
        icons[relativePath] = resized;
      } else {
        // Auto-generate from initials
        icons[relativePath] = await renderIcon(appName: appName, size: size);
      }
    }

    return icons;
  }

  /// Writes icon files to disk under [outputDir].
  static Future<void> writeIconsToDisk(
    String outputDir,
    Map<String, Uint8List> icons,
  ) async {
    for (final entry in icons.entries) {
      final file = File(p.join(outputDir, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
  }

  /// Resizes a PNG image to [targetSize] × [targetSize].
  ///
  /// Uses Flutter's image codec for decoding and a Canvas for re-drawing
  /// at the target resolution.
  static Future<Uint8List> _resizeImage(
    Uint8List sourceBytes,
    int targetSize,
  ) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()));

    // Draw source image scaled to fill target
    canvas.drawImageRect(
      srcImage,
      Rect.fromLTWH(0, 0, srcImage.width.toDouble(), srcImage.height.toDouble()),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(targetSize, targetSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    srcImage.dispose();
    return byteData!.buffer.asUint8List();
  }
}
