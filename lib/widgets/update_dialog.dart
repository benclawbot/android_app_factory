import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_record.dart';
import '../providers/app_provider.dart';
import '../providers/history_provider.dart';
import '../services/app_updater.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatefulWidget {
  final AppRecord record;

  const UpdateDialog({super.key, required this.record});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updateController = TextEditingController();
  final _logScrollController = ScrollController();

  UpdateMode _mode = UpdateMode.smartPatch;
  bool _isUpdating = false;
  double _progress = 0.0;
  final List<String> _logs = [];
  String? _errorMessage;
  bool _done = false;
  String? _selectedFile;

  @override
  void dispose() {
    _updateController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _runUpdate() async {
    final prompt = _updateController.text.trim();
    if (prompt.isEmpty) return;

    final appProv = context.read<AppProvider>();
    if (!appProv.isConfigured) {
      setState(() => _errorMessage = 'Configure your API key in Settings first.');
      return;
    }

    setState(() {
      _isUpdating = true;
      _progress = 0.0;
      _logs.clear();
      _errorMessage = null;
      _done = false;
    });

    try {
      final updater = AppUpdater(
        llmConfig: appProv.llmConfig,
        onLog: (log) {
          if (!mounted) return;
          setState(() => _logs.add(log));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_logScrollController.hasClients) {
              _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
            }
          });
        },
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );

      final updated = await updater.update(
        record: widget.record,
        updatePrompt: prompt,
        mode: _mode,
      );

      if (!mounted) return;

      await context.read<HistoryProvider>().updateRecord(updated);

      setState(() {
        _isUpdating = false;
        _done = true;
        _progress = 1.0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _errorMessage = e.toString();
        _logs.add('Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            gradient: PrimaryGradient.metalSheen,
            borderRadius: BorderRadius.zero,
          ),
          child: const Icon(Icons.edit_note, color: AppColors.onPrimary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update: ${widget.record.appName}',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.record.packageName,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (!_isUpdating)
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 220, child: _buildFileTree()),
        const SizedBox(width: 16),
        Container(width: 1, color: AppColors.outline.withValues(alpha: 0.15)),
        const SizedBox(width: 16),
        Expanded(child: _isUpdating || _done ? _buildProgress() : _buildForm()),
      ],
    );
  }

  Widget _buildFileTree() {
    final ktFiles = widget.record.files.keys.where((k) => k.endsWith('.kt')).toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Files'.toUpperCase(),
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.zero,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: ktFiles.length,
              itemBuilder: (context, i) {
                final path = ktFiles[i];
                final name = path.split('/').last;
                final isSelected = _selectedFile == path;
                return InkWell(
                  onTap: () => setState(() => _selectedFile = path),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(Icons.code, size: 14, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${ktFiles.length} Kotlin file${ktFiles.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to change?'.toUpperCase(),
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.zero,
            ),
            child: TextField(
              controller: _updateController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Examples:\n'
                    '- Add a high scores screen with a leaderboard\n'
                    '- Change the color theme to dark blue\n'
                    '- Add a settings screen with sound toggles\n'
                    '- Replace the list view with a grid layout\n'
                    '- Add share functionality to the detail screen',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintMaxLines: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildModeSelector(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update scope'.toUpperCase(),
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 6),
          _ModeOption(
            value: UpdateMode.smartPatch,
            groupValue: _mode,
            label: 'Smart patch',
            description: 'Only regenerate files that need to change (faster)',
            onChanged: (v) => setState(() => _mode = v!),
          ),
          const SizedBox(height: 4),
          _ModeOption(
            value: UpdateMode.fullRegeneration,
            groupValue: _mode,
            label: 'Full regeneration',
            description: 'Regenerate all source files from scratch',
            onChanged: (v) => setState(() => _mode = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else if (_done)
              const Icon(Icons.check_circle, color: AppColors.success, size: 18)
            else
              const Icon(Icons.error, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Text(
              _done ? 'Update complete!' : 'Updating...',
              style: TextStyle(
                color: _done ? AppColors.success : AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppColors.surfaceContainer,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 2,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.zero,
            ),
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final log = _logs[i];
                final color = log.startsWith('Error') || log.startsWith('e:')
                    ? AppColors.error
                    : log.contains('complete') || log.contains('success')
                        ? AppColors.success
                        : log.startsWith('  File')
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurfaceVariant;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'Consolas',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_done) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    if (_isUpdating) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
        ),
        ElevatedButton.icon(
          onPressed: _updateController.text.isEmpty ? null : _runUpdate,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Update App with AI'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.surfaceContainer,
            disabledForegroundColor: AppColors.onSurfaceVariant,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final UpdateMode value;
  final UpdateMode groupValue;
  final String label;
  final String description;
  final ValueChanged<UpdateMode?> onChanged;

  const _ModeOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
