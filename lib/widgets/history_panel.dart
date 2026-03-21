import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_record.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import 'update_dialog.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    if (!history.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      );
    }

    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _buildHeader(context, history),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _buildGrid(context, history),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, HistoryProvider history) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App History',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${history.records.length} app${history.records.length == 1 ? '' : 's'} generated',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context, HistoryProvider history) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisExtent: 230,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: history.records.length,
        itemBuilder: (context, index) {
          return _AppCard(record: history.records[index]);
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.history_edu,
                size: 52,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No apps generated yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate your first Android app to see it here.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Card ──────────────────────────────────────────────────────────────────

class _AppCard extends StatefulWidget {
  final AppRecord record;

  const _AppCard({required this.record});

  @override
  State<_AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<_AppCard> {
  bool _hovered = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final folderExists = Directory(r.outputPath).existsSync();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.card : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App icon + name row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.android, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.appName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          r.packageName,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status dot
                  Tooltip(
                    message: folderExists ? 'Folder exists on disk' : 'Folder not found',
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: folderExists ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Prompt preview
              Expanded(
                child: Text(
                  r.promptPreview,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 10),

              // Metadata row
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.code,
                    label: '${r.kotlinFileCount} .kt',
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 6),
                  if (r.updates.isNotEmpty)
                    _MetaChip(
                      icon: Icons.edit,
                      label: '${r.updates.length} update${r.updates.length == 1 ? '' : 's'}',
                      color: AppColors.accent,
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(r.updatedAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.launch,
                      label: 'Open',
                      color: AppColors.accent,
                      onTap: folderExists ? () => _openInStudio(r) : null,
                      tooltip: folderExists
                          ? 'Open in Android Studio'
                          : 'Folder not found on disk',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Update',
                      color: AppColors.purple,
                      onTap: () => _showUpdateDialog(context, r),
                      tooltip: 'Update app with AI',
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: '',
                    color: AppColors.error,
                    onTap: _deleting ? null : () => _confirmDelete(context, r),
                    tooltip: 'Delete from history',
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card Actions ──────────────────────────────────────────────────────────────

  void _openInStudio(AppRecord record) {
    // Search for Android Studio
    final studioPaths = [
      r'C:\Program Files\Android\Android Studio\bin\studio64.exe',
      r'C:\Program Files\Android\Android Studio\bin\studio.exe',
    ];

    String? studioExe;
    for (final path in studioPaths) {
      if (File(path).existsSync()) {
        studioExe = path;
        break;
      }
    }

    // Try JetBrains Toolbox path
    if (studioExe == null) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? '';
      final toolboxPath =
          '$appData\\JetBrains\\Toolbox\\apps\\AndroidStudio\\ch-0';
      try {
        final dir = Directory(toolboxPath);
        if (dir.existsSync()) {
          for (final entry in dir.listSync()) {
            final candidate = '${entry.path}\\bin\\studio64.exe';
            if (File(candidate).existsSync()) {
              studioExe = candidate;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (studioExe != null) {
      Process.start(studioExe, [record.outputPath],
          mode: ProcessStartMode.detached);
    } else {
      Process.start('explorer.exe', [record.outputPath],
          mode: ProcessStartMode.detached);
    }
  }

  void _showUpdateDialog(BuildContext context, AppRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(record: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppRecord record) async {
    // Capture provider and id before any async gap
    final hp = context.read<HistoryProvider>();
    final id = record.id;

    final result = await showDialog<_DeleteChoice>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(appName: record.appName),
    );

    if (result == null || !mounted) return;

    setState(() => _deleting = true);
    try {
      await hp.deleteRecord(
        id,
        deleteFiles: result == _DeleteChoice.withFiles,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 30,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: onTap != null
                  ? color.withValues(alpha: 0.10)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: onTap != null
                    ? color.withValues(alpha: 0.25)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: onTap != null ? color : AppColors.textMuted,
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: onTap != null ? color : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delete confirm dialog ─────────────────────────────────────────────────────

enum _DeleteChoice { historyOnly, withFiles }

class _DeleteConfirmDialog extends StatelessWidget {
  final String appName;

  const _DeleteConfirmDialog({required this.appName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 8),
          Text(
            'Delete "$appName"?',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: const Text(
        'How would you like to delete this record?',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(_DeleteChoice.historyOnly),
          icon: const Icon(Icons.history, size: 16),
          label: const Text('History only'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(_DeleteChoice.withFiles),
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Delete + files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
