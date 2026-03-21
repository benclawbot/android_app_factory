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

    if (state.logs.isNotEmpty) _scrollToBottom();

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(genProv, state),

          // Progress bar for generation and build
          if (genProv.isGenerating)
            _buildProgressBar(state),

          // Build phase banner
          if (state.status == GenerationStatus.building ||
              state.status == GenerationStatus.fixing)
            _buildPhaseBanner(state),

          // Log list
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

          // Bottom status bar
          _buildBottomBar(state),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(GenerationProvider genProv, GenerationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
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
          // Build attempt indicator
          if ((state.status == GenerationStatus.building ||
                  state.status == GenerationStatus.fixing) &&
              state.buildAttempt > 0) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Attempt ${state.buildAttempt}/${state.maxBuildAttempts}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar(GenerationState state) {
    final isBuild = state.status == GenerationStatus.building ||
        state.status == GenerationStatus.fixing;

    return LinearProgressIndicator(
      value: isBuild ? null : (state.progress > 0 ? state.progress : null),
      backgroundColor: AppColors.card,
      valueColor: AlwaysStoppedAnimation<Color>(
        isBuild ? AppColors.warning : AppColors.accent,
      ),
      minHeight: 3,
    );
  }

  // ── Phase banner ─────────────────────────────────────────────────────────────

  Widget _buildPhaseBanner(GenerationState state) {
    final isFixing = state.status == GenerationStatus.fixing;
    final color = isFixing ? AppColors.warning : AppColors.accent;
    final icon = isFixing ? Icons.auto_fix_high : Icons.construction;
    final label = isFixing
        ? '🔧 Fixing errors with AI (attempt ${state.buildAttempt}/${state.maxBuildAttempts})...'
        : '🔨 Building APK (attempt ${state.buildAttempt}/${state.maxBuildAttempts})...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom status bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(GenerationState state) {
    // Build success — show APK path
    if (state.status == GenerationStatus.buildSuccess &&
        state.apkPath != null) {
      return _SuccessBar(apkPath: state.apkPath!, outputPath: state.outputPath);
    }

    // Build failed after all attempts
    if (state.status == GenerationStatus.buildFailed) {
      return _FailureBar(
        errorCount: state.buildErrors.length,
        attempts: state.buildAttempt,
      );
    }

    // Code generation complete (no build requested)
    if (state.status == GenerationStatus.complete &&
        state.outputPath != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
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
      );
    }

    return const SizedBox.shrink();
  }

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal,
              size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
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

  // ── Log coloring ──────────────────────────────────────────────────────────────

  Color _getLogColor(String log) {
    if (log.startsWith('❌') ||
        (log.trim().startsWith('e:') && log.contains('.kt:'))) {
      return AppColors.error;
    }
    if (log.startsWith('✅') || log.startsWith('🎉')) return AppColors.success;
    if (log.startsWith('⚡') || log.startsWith('🚀')) return AppColors.accent;
    if (log.startsWith('🔨') || log.startsWith('🔧')) return AppColors.warning;
    if (log.startsWith('  📄') || log.startsWith('  🔧')) {
      return AppColors.textMuted;
    }
    // Gradle output lines (indented or starting with > Task, BUILD, etc.)
    if (log.startsWith('> Task') || log.startsWith('BUILD')) {
      return log.contains('FAILED')
          ? AppColors.error
          : log.contains('SUCCESS')
              ? AppColors.success
              : AppColors.textSecondary;
    }
    if (log.startsWith('w: ')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  // ── Studio/APK openers ────────────────────────────────────────────────────────

  String? _findAndroidStudio() {
    final candidates = [
      r'C:\Program Files\Android\Android Studio\bin\studio64.exe',
      r'C:\Program Files\Android\Android Studio\bin\studio.exe',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    final appData = Platform.environment['LOCALAPPDATA'] ?? '';
    final toolboxPath =
        '$appData\\JetBrains\\Toolbox\\apps\\AndroidStudio\\ch-0';
    try {
      final dir = Directory(toolboxPath);
      if (dir.existsSync()) {
        for (final entry in dir.listSync().whereType<Directory>()) {
          final candidate = '${entry.path}\\bin\\studio64.exe';
          if (File(candidate).existsSync()) return candidate;
        }
      }
    } catch (_) {}
    return null;
  }

  void _openInAndroidStudio(String projectPath) {
    final studio = _findAndroidStudio();
    if (studio != null) {
      Process.start(studio, [projectPath], mode: ProcessStartMode.detached);
    } else {
      Process.start('explorer.exe', [projectPath],
          mode: ProcessStartMode.detached);
    }
  }
}

// ── Success bar ───────────────────────────────────────────────────────────────

class _SuccessBar extends StatelessWidget {
  final String apkPath;
  final String? outputPath;

  const _SuccessBar({required this.apkPath, this.outputPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              const Text(
                '✅ APK built successfully!',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.android, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  apkPath,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.folder_open,
                label: 'Open APK folder',
                color: AppColors.success,
                onTap: () => _openFolder(apkPath),
              ),
              const SizedBox(width: 8),
              if (outputPath != null)
                _ActionBtn(
                  icon: Icons.launch,
                  label: 'Open in Android Studio',
                  color: AppColors.accent,
                  onTap: () => _openInStudio(outputPath!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFolder(String filePath) {
    final dir = File(filePath).parent.path;
    Process.start('explorer.exe', [dir], mode: ProcessStartMode.detached);
  }

  void _openInStudio(String projectPath) {
    final candidates = [
      r'C:\Program Files\Android\Android Studio\bin\studio64.exe',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) {
        Process.start(c, [projectPath], mode: ProcessStartMode.detached);
        return;
      }
    }
    Process.start('explorer.exe', [projectPath],
        mode: ProcessStartMode.detached);
  }
}

// ── Failure bar ───────────────────────────────────────────────────────────────

class _FailureBar extends StatelessWidget {
  final int errorCount;
  final int attempts;

  const _FailureBar({required this.errorCount, required this.attempts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Build failed after $attempts attempt(s) — '
              '$errorCount error(s) remaining.\n'
              'Open the project in Android Studio to fix manually.',
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final GenerationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GenerationStatus.generating => ('Generating', AppColors.accent),
      GenerationStatus.writingFiles => ('Writing Files', AppColors.warning),
      GenerationStatus.building => ('Building', AppColors.warning),
      GenerationStatus.fixing => ('Fixing Errors', AppColors.warning),
      GenerationStatus.complete => ('Complete', AppColors.success),
      GenerationStatus.buildSuccess => ('APK Ready ✅', AppColors.success),
      GenerationStatus.buildFailed => ('Build Failed', AppColors.error),
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
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
