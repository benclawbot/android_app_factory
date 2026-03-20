import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generation_state.dart';
import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final genProv = context.watch<GenerationProvider>();
    final state = genProv.state;

    // Auto scroll on new logs
    if (state.logs.isNotEmpty) {
      _scrollToBottom();
    }

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text(
                  'Console Output',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (state.status != GenerationStatus.idle) ...[
                  _StatusChip(status: state.status),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: genProv.reset,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.textMuted,
                  tooltip: 'Clear console',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),

          // Progress bar
          if (genProv.isGenerating)
            LinearProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              backgroundColor: AppColors.card,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 3,
            ),

          // Console logs
          Expanded(
            child: state.logs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.logs.length,
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 13,
                            height: 1.5,
                            color: _getLogColor(log),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom status
          if (state.status == GenerationStatus.complete &&
              state.outputPath != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Project saved to: ${state.outputPath}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _openInAndroidStudio(state.outputPath!),
                    icon: const Icon(Icons.folder_open, size: 14),
                    label: const Text('Open in Android Studio'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Console output will appear here',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Describe your app and hit Generate',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.startsWith('❌') || log.toLowerCase().contains('error')) {
      return AppColors.error;
    }
    if (log.startsWith('✅') || log.startsWith('🎉')) {
      return AppColors.success;
    }
    if (log.startsWith('⚡') || log.startsWith('🚀')) {
      return AppColors.accent;
    }
    if (log.startsWith('  📄')) {
      return AppColors.textMuted;
    }
    return AppColors.textSecondary;
  }

  /// Finds the Android Studio executable path on Windows.
  String? _findAndroidStudio() {
    // Common installation paths
    final candidates = [
      r'C:\Program Files\Android\Android Studio\bin\studio64.exe',
      r'C:\Program Files\Android\Android Studio\bin\studio.exe',
      // JetBrains Toolbox installations
      r'C:\Users\thoma\AppData\Local\JetBrains\Toolbox\apps\AndroidStudio\**\bin\studio64.exe',
    ];

    for (final candidate in candidates) {
      if (candidate.contains('**')) {
        // Handle wildcard search for JetBrains Toolbox
        final base = candidate.replaceAll('**', '');
        try {
          final dir = Directory(base);
          if (dir.existsSync()) {
            final studios = dir.listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('studio64.exe'))
                .toList();
            if (studios.isNotEmpty) {
              return studios.first.path;
            }
          }
        } catch (_) {}
      } else {
        try {
          if (File(candidate).existsSync()) {
            return candidate;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Opens the project in Android Studio and triggers Gradle sync.
  void _openInAndroidStudio(String projectPath) {
    final studioPath = _findAndroidStudio();

    if (studioPath != null) {
      // Open project in Android Studio
      try {
        Process.start(studioPath, [projectPath]);
      } catch (_) {}
    } else {
      // Fall back to File Explorer if Android Studio not found
      try {
        Process.start('explorer', [projectPath]);
      } catch (_) {}
      return;
    }

    // Trigger Gradle sync in background by running gradlew
    _runGradleSync(projectPath);
  }

  /// Runs `gradlew.bat --refresh-dependencies` in a visible console window.
  void _runGradleSync(String projectPath) {
    final escapedPath = projectPath.replaceAll('/', r'\\');
    final batPath = projectPath + r'\_sync_gradle.bat';
    final batContent = '@echo off\n'
        'title Gradle Sync\n' +
        'cd /d "$escapedPath"\n' +
        'gradlew.bat --refresh-dependencies\n' +
        'echo.\necho === Gradle sync done. You can close this window ===\n' +
        'pause\n';
    try {
      File(batPath).writeAsStringSync(batContent);
      // Start the batch file in a visible console window
      Process.start('cmd.exe', ['/c', 'start', 'cmd', '/k', batPath]);
    } catch (_) {}
  }
}

class _StatusChip extends StatelessWidget {
  final GenerationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GenerationStatus.generating => ('Generating', AppColors.accent),
      GenerationStatus.writingFiles => ('Writing Files', AppColors.warning),
      GenerationStatus.complete => ('Complete', AppColors.success),
      GenerationStatus.error => ('Error', AppColors.error),
      GenerationStatus.idle => ('Idle', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
