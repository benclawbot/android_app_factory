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
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(context, history),
          Container(height: 1, color: AppColors.outline.withValues(alpha: 0.15)),
          Expanded(child: _buildGrid(context, history)),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, HistoryProvider history) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.history, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App History',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${history.records.length} app${history.records.length == 1 ? '' : 's'} generated',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
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
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(
                Icons.history_edu,
                size: 52,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No apps generated yet',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate your first Android app to see it here.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
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
          color: _hovered ? AppColors.surfaceVariant : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.zero,
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
                    decoration: const BoxDecoration(
                      gradient: PrimaryGradient.metalSheen,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.android, color: AppColors.onPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.appName,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          r.packageName,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status indicator (1px dot)
                  Tooltip(
                    message: folderExists ? 'Folder exists on disk' : 'Folder not found',
                    child: Container(
                      width: 6,
                      height: 6,
                      color: folderExists ? AppColors.success : AppColors.warning,
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
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 10),

              // Metadata row - chips
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.code,
                    label: '${r.kotlinFileCount} .kt',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  if (r.updates.isNotEmpty)
                    _MetaChip(
                      icon: Icons.edit,
                      label: '${r.updates.length} update${r.updates.length == 1 ? '' : 's'}',
                      color: AppColors.success,
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(r.updatedAt),
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.outline.withValues(alpha: 0.15)),
              const SizedBox(height: 10),

              // Action buttons
              Row(
                children: [
                  if (r.apkPath != null && File(r.apkPath!).existsSync()) ...[
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.android,
                        label: 'APK',
                        color: AppColors.success,
                        onTap: () => _openApkFolder(r.apkPath!),
                        tooltip: 'Open APK folder',
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.launch,
                      label: 'Open',
                      color: AppColors.primary,
                      onTap: folderExists ? () => _openInStudio(r) : null,
                      tooltip: folderExists ? 'Open in Android Studio' : 'Folder not found on disk',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Update',
                      color: AppColors.primary,
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

  void _openApkFolder(String apkPath) {
    Process.start('explorer.exe', ['/select,', apkPath], mode: ProcessStartMode.detached);
  }

  void _openInStudio(AppRecord record) {
    const studioPath = r'C:\Program Files\Android\Android Studio\bin\studio64.exe';
    if (File(studioPath).existsSync()) {
      Process.start(studioPath, [record.outputPath], mode: ProcessStartMode.detached);
    } else {
      Process.start('explorer.exe', [record.outputPath], mode: ProcessStartMode.detached);
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
    final hp = context.read<HistoryProvider>();
    final id = record.id;

    final result = await showDialog<_DeleteChoice>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(appName: record.appName),
    );

    if (result == null || !mounted) return;

    setState(() => _deleting = true);
    try {
      await hp.deleteRecord(id, deleteFiles: result == _DeleteChoice.withFiles);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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

// ── Chips ─────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 30,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 8, vertical: 5),
            decoration: BoxDecoration(
              color: onTap != null ? color.withValues(alpha: 0.10) : AppColors.surfaceContainer,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: onTap != null ? color.withValues(alpha: 0.25) : AppColors.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: onTap != null ? color : AppColors.onSurfaceVariant),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: onTap != null ? color : AppColors.onSurfaceVariant,
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

// ── Delete Dialog ─────────────────────────────────────────────────────────────

enum _DeleteChoice { historyOnly, withFiles }

class _DeleteConfirmDialog extends StatelessWidget {
  final String appName;

  const _DeleteConfirmDialog({required this.appName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete "$appName"?',
              style: const TextStyle(color: AppColors.onSurface, fontSize: 16),
            ),
          ),
        ],
      ),
      content: const Text(
        'How would you like to delete this record?',
        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_DeleteChoice.historyOnly),
          icon: const Icon(Icons.history, size: 16),
          label: const Text('History only'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            side: const GhostBorder(),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(_DeleteChoice.withFiles),
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Delete + files'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ],
    );
  }
}
