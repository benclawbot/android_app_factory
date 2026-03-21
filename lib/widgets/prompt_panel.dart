import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../providers/app_provider.dart';
import '../providers/generation_provider.dart';
import '../providers/history_provider.dart';
import '../services/icon_generator.dart';
import '../theme/app_theme.dart';

class PromptPanel extends StatefulWidget {
  const PromptPanel({super.key});

  @override
  State<PromptPanel> createState() => _PromptPanelState();
}

class _PromptPanelState extends State<PromptPanel> {
  final _promptController = TextEditingController();
  final _appNameController = TextEditingController(text: 'MyApp');
  final _packageController = TextEditingController(text: 'com.app.myapp');

  // Icon preview state
  Uint8List? _iconPreviewBytes;
  bool _iconLoading = false;

  @override
  void initState() {
    super.initState();
    // Generate initial icon preview
    _regenerateIconPreview('MyApp');
  }

  @override
  void dispose() {
    _promptController.dispose();
    _appNameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  /// Derives a clean package name from [appName].
  ///
  /// "Recipe Book" → "com.app.recipebook"
  /// "My Cool App!" → "com.app.mycoolapp"
  String _derivePackageName(String appName) {
    final sanitized = appName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (sanitized.isEmpty) return 'com.app.myapp';
    return 'com.app.$sanitized';
  }

  /// Called when the app name field changes — auto-updates package name and icon.
  void _onAppNameChanged(String value) {
    final appProv = context.read<AppProvider>();
    appProv.setAppName(value);

    // Auto-update package name
    final pkg = _derivePackageName(value);
    _packageController.text = pkg;
    appProv.setPackageName(pkg);

    // Regenerate icon preview (only if not using a custom icon)
    if (appProv.customIconPath == null) {
      _regenerateIconPreview(value);
    }
  }

  /// Renders a fresh icon preview from the app name.
  Future<void> _regenerateIconPreview(String appName, {String? customPath}) async {
    if (_iconLoading) return;
    setState(() => _iconLoading = true);

    try {
      Uint8List bytes;
      if (customPath != null && File(customPath).existsSync()) {
        bytes = await File(customPath).readAsBytes();
      } else {
        bytes = await IconGenerator.renderIcon(
          appName: appName.isEmpty ? 'App' : appName,
          size: 192,
        );
      }
      if (mounted) {
        setState(() {
          _iconPreviewBytes = bytes;
          _iconLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _iconLoading = false);
    }
  }

  /// Lets the user pick a custom icon image file.
  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Select app icon image',
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final appProv = context.read<AppProvider>();
    appProv.setCustomIconPath(filePath);
    _regenerateIconPreview(_appNameController.text.trim(), customPath: filePath);
  }

  /// Clears the custom icon and reverts to auto-generated.
  void _clearCustomIcon() {
    final appProv = context.read<AppProvider>();
    appProv.setCustomIconPath(null);
    _regenerateIconPreview(_appNameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final genProv = context.watch<GenerationProvider>();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: PrimaryGradient.metalSheen,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.onPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe Your App',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                    ),
                  ),
                  Text(
                    'Tell the AI what Android app you want to build',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App name, icon, and package row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon preview + import
              _buildIconSection(appProv),
              const SizedBox(width: 16),

              // App Name & Package stacked
              Expanded(
                child: Column(
                  children: [
                    _buildField(
                      label: 'App Name',
                      controller: _appNameController,
                      hint: 'MyApp',
                      icon: Icons.apps,
                      onChanged: _onAppNameChanged,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Package Name',
                      controller: _packageController,
                      hint: 'com.app.myapp',
                      icon: Icons.inventory_2,
                      onChanged: (v) => appProv.setPackageName(v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Output directory picker
          _buildOutputDirPicker(appProv),
          const SizedBox(height: 16),

          // Prompt input
          const Text(
            'APP DESCRIPTION',
            style: TextStyle(
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
              ),
              child: TextField(
                controller: _promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Example: A recipe book app with a home screen showing recipe cards, '
                      'a detail page for each recipe with ingredients and steps, '
                      'an add recipe screen with a form, and a favorites screen. '
                      'Use a warm color palette with orange accents...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintMaxLines: 5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-build row
          _buildAutoBuildRow(appProv),
          const SizedBox(height: 12),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: genProv.isGenerating || !appProv.isConfigured
                  ? null
                  : () => _generate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.surfaceContainer,
                disabledForegroundColor: AppColors.onSurfaceVariant,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              child: genProv.isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          appProv.isConfigured
                              ? 'Generate Android App'
                              : 'Configure API Key First',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon section ──────────────────────────────────────────────────────────────

  Widget _buildIconSection(AppProvider appProv) {
    return Column(
      children: [
        Text(
          'APP ICON',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        // Icon preview container
        GestureDetector(
          onTap: _pickIcon,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: _iconLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  : _iconPreviewBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.memory(
                            _iconPreviewBytes!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate,
                          color: AppColors.onSurfaceVariant,
                          size: 28,
                        ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Action buttons under icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Import custom icon',
              child: InkWell(
                onTap: _pickIcon,
                borderRadius: BorderRadius.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.upload, size: 14, color: AppColors.primary),
                ),
              ),
            ),
            if (appProv.customIconPath != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Reset to auto-generated',
                child: InkWell(
                  onTap: _clearCustomIcon,
                  borderRadius: BorderRadius.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Field builder ─────────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: AppColors.surfaceContainerLowest,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  // ── Output directory picker ───────────────────────────────────────────────────

  Widget _buildOutputDirPicker(AppProvider appProv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUTPUT DIRECTORY',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    appProv.outputDirectory.isEmpty
                        ? 'Select output folder...'
                        : appProv.outputDirectory,
                    style: TextStyle(
                      color: appProv.outputDirectory.isEmpty
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final dir = await FilePicker.platform.getDirectoryPath();
                    if (dir != null) {
                      appProv.setOutputDirectory(dir);
                    }
                  },
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Browse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.onSurface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Auto-build row ────────────────────────────────────────────────────────────

  Widget _buildAutoBuildRow(AppProvider appProv) {
    const attempts = [1, 2, 3, 5];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.zero,
        border: appProv.autoBuild
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: appProv.autoBuild,
              onChanged: (v) => appProv.setAutoBuild(v ?? true),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.onSurfaceVariant, width: 1.5),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Build APK & auto-fix errors',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  appProv.autoBuild
                      ? 'Compile with Gradle after generation, fix errors with AI'
                      : 'Skip build — generate code only',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (appProv.autoBuild) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Max fix attempts',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                  ),
                  child: DropdownButton<int>(
                    value: attempts.contains(appProv.maxBuildAttempts)
                        ? appProv.maxBuildAttempts
                        : 3,
                    items: attempts
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(
                                '$n',
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) appProv.setMaxBuildAttempts(v);
                    },
                    dropdownColor: AppColors.surfaceContainerHighest,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    icon: const Icon(Icons.expand_more,
                        size: 16, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Generate ──────────────────────────────────────────────────────────────────

  void _generate(BuildContext context) {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the app you want to build')),
      );
      return;
    }

    final appProv = context.read<AppProvider>();
    if (appProv.outputDirectory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an output directory')),
      );
      return;
    }

    final outputPath = p.join(
      appProv.outputDirectory,
      _appNameController.text.trim().replaceAll(' ', '_').toLowerCase(),
    );

    context.read<GenerationProvider>().generateApp(
          prompt: prompt,
          outputDir: outputPath,
          appName: _appNameController.text.trim(),
          packageName: _packageController.text.trim(),
          llmConfig: appProv.llmConfig,
          historyProvider: context.read<HistoryProvider>(),
          autoBuild: appProv.autoBuild,
          maxBuildAttempts: appProv.maxBuildAttempts,
          customIconPath: appProv.customIconPath,
        );
  }
}
