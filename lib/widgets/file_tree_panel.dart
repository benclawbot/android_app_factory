import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../providers/generation_provider.dart';
import '../models/generation_state.dart';
import '../theme/app_theme.dart';

class FileTreePanel extends StatefulWidget {
  const FileTreePanel({super.key});

  @override
  State<FileTreePanel> createState() => _FileTreePanelState();
}

class _FileTreePanelState extends State<FileTreePanel> {
  String? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final genProv = context.watch<GenerationProvider>();
    final files = genProv.state.generatedFiles;

    if (genProv.state.status == GenerationStatus.idle || files.isEmpty) {
      return _buildEmptyState();
    }

    return Row(
      children: [
        // File tree (left)
        Container(
          width: 280,
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Generated Files',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${files.length}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // File list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: files.keys.length,
                  itemBuilder: (context, index) {
                    final path = files.keys.elementAt(index);
                    final isSelected = path == _selectedFile;
                    return _FileItem(
                      path: path,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedFile = path),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        // File content viewer (right)
        Expanded(
          child: _selectedFile != null && files.containsKey(_selectedFile)
              ? _buildFileViewer(files[_selectedFile]!, _selectedFile!)
              : _buildSelectPrompt(),
        ),
      ],
    );
  }

  Widget _buildFileViewer(String content, String filename) {
    final lang = filename.endsWith('.kt')
        ? 'kotlin'
        : filename.endsWith('.xml')
            ? 'xml'
            : filename.endsWith('.gradle.kts')
                ? 'kotlin'
                : filename.endsWith('.properties')
                    ? 'properties'
                    : filename.endsWith('.toml')
                        ? 'toml'
                        : 'plaintext';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Icon(_getFileIcon(filename), size: 16, color: _getFileColor(filename)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filename,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Consolas',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${content.split('\n').length} lines',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: HighlightView(
              content,
              language: lang,
              theme: monokaiSublimeTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No generated files yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate an app from the Generate tab first',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return const Center(
      child: Text(
        'Select a file to view its contents',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.kt')) return Icons.code;
    if (filename.endsWith('.xml')) return Icons.description;
    if (filename.endsWith('.gradle.kts')) return Icons.build;
    if (filename.endsWith('.properties')) return Icons.settings;
    if (filename.endsWith('.toml')) return Icons.list;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String filename) {
    if (filename.endsWith('.kt')) return const Color(0xFF7F52FF); // Kotlin purple
    if (filename.endsWith('.xml')) return AppColors.warning;
    if (filename.endsWith('.gradle.kts')) return AppColors.accent;
    return AppColors.textMuted;
  }
}

class _FileItem extends StatefulWidget {
  final String path;
  final bool isSelected;
  final VoidCallback onTap;

  const _FileItem({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filename = widget.path.split('/').last;
    final dir = widget.path.contains('/')
        ? widget.path.substring(0, widget.path.lastIndexOf('/'))
        : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: widget.isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : _hovered
                  ? AppColors.card.withValues(alpha: 0.5)
                  : Colors.transparent,
          child: Row(
            children: [
              Icon(
                _getIcon(filename),
                size: 16,
                color: _getColor(filename),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: TextStyle(
                        color: widget.isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dir.isNotEmpty)
                      Text(
                        dir,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String filename) {
    if (filename.endsWith('.kt')) return Icons.code;
    if (filename.endsWith('.xml')) return Icons.description;
    if (filename.endsWith('.gradle.kts')) return Icons.build;
    if (filename.endsWith('.properties')) return Icons.settings;
    if (filename.endsWith('.toml')) return Icons.list;
    return Icons.insert_drive_file;
  }

  Color _getColor(String filename) {
    if (filename.endsWith('.kt')) return const Color(0xFF7F52FF);
    if (filename.endsWith('.xml')) return AppColors.warning;
    if (filename.endsWith('.gradle.kts')) return AppColors.accent;
    return AppColors.textMuted;
  }
}
