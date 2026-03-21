import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Generates Android launcher icons that visually represent what the app does.
///
/// Design strategy (modelled on top App Store / Google Play icon patterns):
///   1. **Single focal symbol** — one recognizable icon glyph, centered
///   2. **Bold gradient background** — two-tone gradient for depth & modernity
///   3. **White symbol** with subtle drop shadow for contrast
///   4. **Rounded-rect clip** matching Android adaptive-icon safe zone
///   5. **No text** — purely visual, scales perfectly at every density
///
/// The generator maps keywords in the app name to the best-matching Material
/// Icon codepoint. If no keyword matches it falls back to a contextual
/// "category guess" and ultimately to an abstract app-grid symbol.
class IconGenerator {
  IconGenerator._();

  // ── Android mipmap densities ──────────────────────────────────────────────

  static const _densities = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // ── Keyword → Icon mapping ────────────────────────────────────────────────
  //
  // Each entry maps a set of keywords (that might appear in an app name) to a
  // Material Icons codepoint + a curated gradient pair.  Ordered so that more
  // specific keywords come first; first match wins.

  static final _iconMappings = <_IconMapping>[
    // ── Food & Drink ─────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['recipe', 'cook', 'food', 'meal', 'kitchen', 'chef', 'dish', 'dinner', 'lunch', 'breakfast'],
      icon: Icons.restaurant_menu,
      gradientStart: Color(0xFFFF6B35),
      gradientEnd: Color(0xFFD32F2F),
    ),
    _IconMapping(
      keywords: ['coffee', 'cafe', 'tea', 'brew', 'barista'],
      icon: Icons.coffee,
      gradientStart: Color(0xFF8D6E63),
      gradientEnd: Color(0xFF4E342E),
    ),
    _IconMapping(
      keywords: ['drink', 'cocktail', 'bar', 'wine', 'beer', 'juice', 'smoothie'],
      icon: Icons.local_bar,
      gradientStart: Color(0xFFAB47BC),
      gradientEnd: Color(0xFF6A1B9A),
    ),
    _IconMapping(
      keywords: ['grocery', 'market', 'shop', 'store', 'cart', 'buy', 'ecommerce', 'commerce'],
      icon: Icons.shopping_cart,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF2E7D32),
    ),

    // ── Health & Fitness ─────────────────────────────────────────────────
    _IconMapping(
      keywords: ['fitness', 'gym', 'workout', 'exercise', 'training', 'muscle'],
      icon: Icons.fitness_center,
      gradientStart: Color(0xFFEF5350),
      gradientEnd: Color(0xFFB71C1C),
    ),
    _IconMapping(
      keywords: ['health', 'medical', 'doctor', 'hospital', 'clinic', 'medicine', 'pharma'],
      icon: Icons.favorite,
      gradientStart: Color(0xFFE91E63),
      gradientEnd: Color(0xFFAD1457),
    ),
    _IconMapping(
      keywords: ['yoga', 'meditat', 'mindful', 'calm', 'relax', 'zen', 'wellness'],
      icon: Icons.self_improvement,
      gradientStart: Color(0xFF26C6DA),
      gradientEnd: Color(0xFF00838F),
    ),
    _IconMapping(
      keywords: ['run', 'jog', 'marathon', 'sprint', 'track', 'step'],
      icon: Icons.directions_run,
      gradientStart: Color(0xFFFF7043),
      gradientEnd: Color(0xFFBF360C),
    ),

    // ── Music & Audio ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['music', 'song', 'playlist', 'melody', 'tune', 'sound', 'audio', 'beat'],
      icon: Icons.music_note,
      gradientStart: Color(0xFFEC407A),
      gradientEnd: Color(0xFF880E4F),
    ),
    _IconMapping(
      keywords: ['podcast', 'radio', 'listen'],
      icon: Icons.headphones,
      gradientStart: Color(0xFF7E57C2),
      gradientEnd: Color(0xFF4527A0),
    ),
    _IconMapping(
      keywords: ['record', 'voice', 'mic', 'microphone'],
      icon: Icons.mic,
      gradientStart: Color(0xFFFF5722),
      gradientEnd: Color(0xFFBF360C),
    ),

    // ── Photo & Video ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['photo', 'camera', 'picture', 'image', 'snap', 'selfie', 'gallery'],
      icon: Icons.camera_alt,
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF1565C0),
    ),
    _IconMapping(
      keywords: ['video', 'movie', 'film', 'stream', 'watch', 'tv', 'cinema'],
      icon: Icons.videocam,
      gradientStart: Color(0xFFE53935),
      gradientEnd: Color(0xFF7B1FA2),
    ),

    // ── Social & Chat ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['chat', 'message', 'messenger', 'sms', 'text', 'inbox'],
      icon: Icons.chat_bubble,
      gradientStart: Color(0xFF29B6F6),
      gradientEnd: Color(0xFF0277BD),
    ),
    _IconMapping(
      keywords: ['social', 'community', 'friend', 'connect', 'network', 'people', 'group'],
      icon: Icons.people,
      gradientStart: Color(0xFF5C6BC0),
      gradientEnd: Color(0xFF283593),
    ),
    _IconMapping(
      keywords: ['call', 'phone', 'dial', 'contact'],
      icon: Icons.phone,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF2E7D32),
    ),

    // ── Productivity & Notes ─────────────────────────────────────────────
    _IconMapping(
      keywords: ['note', 'memo', 'journal', 'diary', 'write', 'writing'],
      icon: Icons.edit_note,
      gradientStart: Color(0xFFFFA726),
      gradientEnd: Color(0xFFE65100),
    ),
    _IconMapping(
      keywords: ['task', 'todo', 'checklist', 'planner', 'organiz', 'productiv'],
      icon: Icons.check_circle,
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF1565C0),
    ),
    _IconMapping(
      keywords: ['calendar', 'schedule', 'event', 'booking', 'appointment', 'date'],
      icon: Icons.calendar_today,
      gradientStart: Color(0xFF5C6BC0),
      gradientEnd: Color(0xFF283593),
    ),
    _IconMapping(
      keywords: ['timer', 'clock', 'alarm', 'stopwatch', 'time', 'pomodoro'],
      icon: Icons.timer,
      gradientStart: Color(0xFF78909C),
      gradientEnd: Color(0xFF37474F),
    ),
    _IconMapping(
      keywords: ['calculator', 'math', 'calc', 'compute'],
      icon: Icons.calculate,
      gradientStart: Color(0xFF607D8B),
      gradientEnd: Color(0xFF263238),
    ),

    // ── Finance & Money ──────────────────────────────────────────────────
    _IconMapping(
      keywords: ['finance', 'money', 'bank', 'payment', 'pay', 'wallet', 'budget', 'expense', 'invest'],
      icon: Icons.account_balance_wallet,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF1B5E20),
    ),
    _IconMapping(
      keywords: ['crypto', 'bitcoin', 'trading', 'stock', 'market'],
      icon: Icons.show_chart,
      gradientStart: Color(0xFFFFB300),
      gradientEnd: Color(0xFFFF6F00),
    ),

    // ── Travel & Maps ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['travel', 'trip', 'vacation', 'holiday', 'tour', 'adventure'],
      icon: Icons.flight,
      gradientStart: Color(0xFF29B6F6),
      gradientEnd: Color(0xFF01579B),
    ),
    _IconMapping(
      keywords: ['map', 'navigation', 'location', 'gps', 'direction', 'route'],
      icon: Icons.map,
      gradientStart: Color(0xFF26A69A),
      gradientEnd: Color(0xFF004D40),
    ),
    _IconMapping(
      keywords: ['weather', 'forecast', 'climate', 'rain', 'sun', 'temperature'],
      icon: Icons.wb_sunny,
      gradientStart: Color(0xFFFFCA28),
      gradientEnd: Color(0xFFF57F17),
    ),

    // ── Education & Learning ─────────────────────────────────────────────
    _IconMapping(
      keywords: ['learn', 'study', 'education', 'school', 'university', 'course', 'lesson', 'tutor'],
      icon: Icons.school,
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF0D47A1),
    ),
    _IconMapping(
      keywords: ['book', 'read', 'library', 'ebook', 'literature', 'novel', 'story'],
      icon: Icons.menu_book,
      gradientStart: Color(0xFF8D6E63),
      gradientEnd: Color(0xFF3E2723),
    ),
    _IconMapping(
      keywords: ['quiz', 'trivia', 'question', 'test', 'exam'],
      icon: Icons.quiz,
      gradientStart: Color(0xFFAB47BC),
      gradientEnd: Color(0xFF6A1B9A),
    ),
    _IconMapping(
      keywords: ['language', 'translat', 'vocabular', 'dictionary', 'word'],
      icon: Icons.translate,
      gradientStart: Color(0xFF5C6BC0),
      gradientEnd: Color(0xFF1A237E),
    ),

    // ── Games & Entertainment ────────────────────────────────────────────
    _IconMapping(
      keywords: ['game', 'play', 'gaming', 'arcade', 'puzzle', 'level'],
      icon: Icons.sports_esports,
      gradientStart: Color(0xFF7C4DFF),
      gradientEnd: Color(0xFF311B92),
    ),
    _IconMapping(
      keywords: ['sport', 'football', 'soccer', 'basketball', 'baseball', 'tennis', 'golf'],
      icon: Icons.sports_soccer,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF1B5E20),
    ),

    // ── Home & Lifestyle ─────────────────────────────────────────────────
    _IconMapping(
      keywords: ['home', 'house', 'smart home', 'iot', 'device', 'automation'],
      icon: Icons.home,
      gradientStart: Color(0xFF29B6F6),
      gradientEnd: Color(0xFF0277BD),
    ),
    _IconMapping(
      keywords: ['pet', 'dog', 'cat', 'animal', 'vet'],
      icon: Icons.pets,
      gradientStart: Color(0xFFFFB74D),
      gradientEnd: Color(0xFFE65100),
    ),
    _IconMapping(
      keywords: ['plant', 'garden', 'flower', 'nature', 'green', 'eco', 'environment'],
      icon: Icons.eco,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF1B5E20),
    ),
    _IconMapping(
      keywords: ['fashion', 'clothes', 'outfit', 'style', 'wardrobe', 'dress'],
      icon: Icons.checkroom,
      gradientStart: Color(0xFFEC407A),
      gradientEnd: Color(0xFF880E4F),
    ),

    // ── Tools & Utilities ────────────────────────────────────────────────
    _IconMapping(
      keywords: ['scan', 'qr', 'barcode', 'scanner'],
      icon: Icons.qr_code_scanner,
      gradientStart: Color(0xFF78909C),
      gradientEnd: Color(0xFF263238),
    ),
    _IconMapping(
      keywords: ['file', 'document', 'pdf', 'folder', 'storage', 'drive', 'cloud'],
      icon: Icons.folder,
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF1565C0),
    ),
    _IconMapping(
      keywords: ['password', 'security', 'lock', 'auth', 'protect', 'safe', 'vault'],
      icon: Icons.lock,
      gradientStart: Color(0xFF78909C),
      gradientEnd: Color(0xFF37474F),
    ),
    _IconMapping(
      keywords: ['setting', 'config', 'preference', 'option', 'control'],
      icon: Icons.settings,
      gradientStart: Color(0xFF90A4AE),
      gradientEnd: Color(0xFF455A64),
    ),
    _IconMapping(
      keywords: ['flashlight', 'torch', 'light'],
      icon: Icons.flashlight_on,
      gradientStart: Color(0xFFFFCA28),
      gradientEnd: Color(0xFFF57F17),
    ),

    // ── Art & Design ─────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['art', 'draw', 'paint', 'sketch', 'canvas', 'design', 'creative'],
      icon: Icons.palette,
      gradientStart: Color(0xFFEC407A),
      gradientEnd: Color(0xFF7B1FA2),
    ),

    // ── News & Content ───────────────────────────────────────────────────
    _IconMapping(
      keywords: ['news', 'article', 'blog', 'magazine', 'press', 'feed'],
      icon: Icons.article,
      gradientStart: Color(0xFF5C6BC0),
      gradientEnd: Color(0xFF283593),
    ),

    // ── Communication ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['email', 'mail', 'envelope'],
      icon: Icons.email,
      gradientStart: Color(0xFF42A5F5),
      gradientEnd: Color(0xFF1565C0),
    ),

    // ── Delivery & Logistics ─────────────────────────────────────────────
    _IconMapping(
      keywords: ['delivery', 'shipping', 'package', 'order', 'tracking'],
      icon: Icons.local_shipping,
      gradientStart: Color(0xFFFFB74D),
      gradientEnd: Color(0xFFE65100),
    ),

    // ── Habit & Goals ────────────────────────────────────────────────────
    _IconMapping(
      keywords: ['habit', 'goal', 'streak', 'routine', 'daily', 'progress'],
      icon: Icons.flag,
      gradientStart: Color(0xFF66BB6A),
      gradientEnd: Color(0xFF2E7D32),
    ),
  ];

  // ── Default fallback ──────────────────────────────────────────────────────

  static final _defaultMapping = _IconMapping(
    keywords: [],
    icon: Icons.apps,
    gradientStart: Color(0xFF5C6BC0),
    gradientEnd: Color(0xFF283593),
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Finds the best icon mapping for the given [appName].
  static _IconMapping _matchIcon(String appName) {
    final lower = appName.toLowerCase();
    for (final mapping in _iconMappings) {
      for (final keyword in mapping.keywords) {
        if (lower.contains(keyword)) return mapping;
      }
    }
    return _defaultMapping;
  }

  /// Derives 1-2 letter initials from [appName] (used as fallback only).
  static String initials(String appName) {
    final words = appName.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    final name = words.first;
    final caps = name.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).toList();
    if (caps.length >= 2) return '${caps[0]}${caps[1]}';
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  /// Returns the accent color that would be used for the given app name.
  static Color accentColorFor(String appName) {
    return _matchIcon(appName).gradientStart;
  }

  /// Renders a professional app-store-style icon as PNG bytes.
  ///
  /// The icon features:
  /// - A bold gradient background (two-tone, 135° angle)
  /// - A centered white Material Icon symbol that represents the app's purpose
  /// - Subtle depth via a background circle highlight
  /// - Rounded-rect shape matching Android launcher icon standards
  static Future<Uint8List> renderIcon({
    required String appName,
    required int size,
    int? seed,
  }) async {
    final mapping = _matchIcon(appName);
    final s = size.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, s, s),
    );

    // ── 1. Background gradient ──────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(s, s),
        [mapping.gradientStart, mapping.gradientEnd],
      );
    final radius = s * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(radius)),
      bgPaint,
    );

    // ── 2. Subtle highlight circle (top-left glow) ──────────────────────
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(s * 0.3, s * 0.3),
        s * 0.6,
        [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(radius)),
      glowPaint,
    );

    // ── 3. Icon symbol ──────────────────────────────────────────────────
    // We draw the Material Icon glyph using a paragraph with the
    // MaterialIcons font family.
    final iconSize = s * 0.48;
    final iconCodePoint = mapping.icon.codePoint;
    final iconFontFamily = mapping.icon.fontFamily ?? 'MaterialIcons';

    // Shadow layer
    final shadowBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
    )
      ..pushStyle(ui.TextStyle(
        fontFamily: iconFontFamily,
        fontSize: iconSize,
        color: Colors.black.withValues(alpha: 0.2),
      ))
      ..addText(String.fromCharCode(iconCodePoint));
    final shadowParagraph = shadowBuilder.build()
      ..layout(ui.ParagraphConstraints(width: s));
    final shadowY = (s - shadowParagraph.height) / 2 + s * 0.02;
    canvas.drawParagraph(shadowParagraph, Offset(0, shadowY));

    // Main icon (white)
    final iconBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
    )
      ..pushStyle(ui.TextStyle(
        fontFamily: iconFontFamily,
        fontSize: iconSize,
        color: const Color(0xFFFFFFFF),
      ))
      ..addText(String.fromCharCode(iconCodePoint));
    final iconParagraph = iconBuilder.build()
      ..layout(ui.ParagraphConstraints(width: s));
    final iconY = (s - iconParagraph.height) / 2;
    canvas.drawParagraph(iconParagraph, Offset(0, iconY));

    // ── 4. Encode to PNG ────────────────────────────────────────────────
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Generates all mipmap-density icons and returns a map of
  /// relative path → PNG bytes.
  static Future<Map<String, Uint8List>> generateMipmapIcons({
    required String appName,
    String? customIconPath,
    int? seed,
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
        icons[relativePath] = await _resizeImage(customBytes, size);
      } else {
        icons[relativePath] = await renderIcon(
          appName: appName,
          size: size,
          seed: seed,
        );
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
  static Future<Uint8List> _resizeImage(
    Uint8List sourceBytes,
    int targetSize,
  ) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
    );

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

/// Internal data class: keyword set → icon + gradient pair.
class _IconMapping {
  final List<String> keywords;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  const _IconMapping({
    required this.keywords,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
