import 'dart:convert';

class UpdateEntry {
  final String prompt;
  final DateTime timestamp;
  final List<String> modifiedFiles;

  const UpdateEntry({
    required this.prompt,
    required this.timestamp,
    required this.modifiedFiles,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'timestamp': timestamp.toIso8601String(),
        'modifiedFiles': modifiedFiles,
      };

  factory UpdateEntry.fromJson(Map<String, dynamic> json) => UpdateEntry(
        prompt: json['prompt'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        modifiedFiles: List<String>.from(json['modifiedFiles'] as List),
      );
}

class AppRecord {
  final String id;
  final String appName;
  final String packageName;
  final String outputPath;
  final String originalPrompt;
  final Map<String, String> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UpdateEntry> updates;

  const AppRecord({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.outputPath,
    required this.originalPrompt,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    this.updates = const [],
  });

  AppRecord copyWith({
    String? appName,
    String? packageName,
    String? outputPath,
    String? originalPrompt,
    Map<String, String>? files,
    DateTime? updatedAt,
    List<UpdateEntry>? updates,
  }) {
    return AppRecord(
      id: id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      outputPath: outputPath ?? this.outputPath,
      originalPrompt: originalPrompt ?? this.originalPrompt,
      files: files ?? this.files,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updates: updates ?? this.updates,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'packageName': packageName,
        'outputPath': outputPath,
        'originalPrompt': originalPrompt,
        'files': files,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'updates': updates.map((u) => u.toJson()).toList(),
      };

  factory AppRecord.fromJson(Map<String, dynamic> json) => AppRecord(
        id: json['id'] as String,
        appName: json['appName'] as String,
        packageName: json['packageName'] as String,
        outputPath: json['outputPath'] as String,
        originalPrompt: json['originalPrompt'] as String,
        files: Map<String, String>.from(json['files'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        updates: (json['updates'] as List<dynamic>? ?? [])
            .map((u) => UpdateEntry.fromJson(u as Map<String, dynamic>))
            .toList(),
      );

  /// How many source .kt files are in this record
  int get kotlinFileCount =>
      files.keys.where((k) => k.endsWith('.kt')).length;

  /// Short prompt preview for display
  String get promptPreview {
    const maxLen = 120;
    if (originalPrompt.length <= maxLen) return originalPrompt;
    return '${originalPrompt.substring(0, maxLen)}…';
  }

  String toJsonString() => jsonEncode(toJson());
  static AppRecord fromJsonString(String s) =>
      AppRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
