import 'dart:convert';

enum BuildStatus { notBuilt, success, failed }

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

  // Build phase fields
  final BuildStatus buildStatus;
  final String? apkPath;
  final int buildAttempts;

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
    this.buildStatus = BuildStatus.notBuilt,
    this.apkPath,
    this.buildAttempts = 0,
  });

  AppRecord copyWith({
    String? appName,
    String? packageName,
    String? outputPath,
    String? originalPrompt,
    Map<String, String>? files,
    DateTime? updatedAt,
    List<UpdateEntry>? updates,
    BuildStatus? buildStatus,
    String? apkPath,
    int? buildAttempts,
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
      buildStatus: buildStatus ?? this.buildStatus,
      apkPath: apkPath ?? this.apkPath,
      buildAttempts: buildAttempts ?? this.buildAttempts,
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
        'buildStatus': buildStatus.name,
        'apkPath': apkPath,
        'buildAttempts': buildAttempts,
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
        buildStatus: BuildStatus.values.firstWhere(
          (s) => s.name == (json['buildStatus'] as String? ?? 'notBuilt'),
          orElse: () => BuildStatus.notBuilt,
        ),
        apkPath: json['apkPath'] as String?,
        buildAttempts: (json['buildAttempts'] as int?) ?? 0,
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
