import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../models/llm_config.dart';
import '../providers/app_provider.dart';
import '../providers/generation_provider.dart';
import '../providers/history_provider.dart';
import '../services/icon_generator.dart';
import '../services/llm_service.dart';
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
  final _appNameFocusNode = FocusNode();

  // Icon preview state
  Uint8List? _iconPreviewBytes;
  bool _iconLoading = false;

  // Description generation state
  bool _descriptionLoading = false;

  // Track previous app name to avoid redundant regeneration
  String _lastGeneratedName = '';

  @override
  void initState() {
    super.initState();
    // Generate initial icon
    _regenerateIcon('MyApp');
    // Listen for app name field losing focus
    _appNameFocusNode.addListener(_onAppNameFocusChanged);
  }

  @override
  void dispose() {
    _appNameFocusNode.removeListener(_onAppNameFocusChanged);
    _appNameFocusNode.dispose();
    _promptController.dispose();
    _appNameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  // ── Auto-generation triggers ──────────────────────────────────────────────

  /// Called when the app name field gains or loses focus.
  void _onAppNameFocusChanged() {
    if (!_appNameFocusNode.hasFocus) {
      // Focus lost — finalize the app name
      final name = _appNameController.text.trim();
      if (name.isEmpty || name == _lastGeneratedName) return;
      _lastGeneratedName = name;

      final appProv = context.read<AppProvider>();
      // Auto-generate icon (unless custom icon is set)
      if (appProv.customIconPath == null) {
        _regenerateIcon(name);
      }
      // Auto-generate description (only if description is empty)
      if (_promptController.text.trim().isEmpty && appProv.isConfigured) {
        _generateDescription(name, appProv.llmConfig);
      }
    }
  }

  /// Derives a clean package name from [appName].
  String _derivePackageName(String appName) {
    final sanitized = appName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (sanitized.isEmpty) return 'com.app.myapp';
    return 'com.app.$sanitized';
  }

  /// Called as user types in the app name field — only updates package name.
  void _onAppNameChanged(String value) {
    final appProv = context.read<AppProvider>();
    appProv.setAppName(value);

    // Auto-update package name in real-time
    final pkg = _derivePackageName(value);
    _packageController.text = pkg;
    appProv.setPackageName(pkg);
  }

  // ── Icon generation ───────────────────────────────────────────────────────

  /// Renders a fresh icon preview.
  Future<void> _regenerateIcon(String appName, {String? customPath}) async {
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

  /// Manual regenerate button for icon — forces re-render.
  void _onRegenerateIcon() {
    final appProv = context.read<AppProvider>();
    if (appProv.customIconPath != null) return; // custom icon set, no regen
    final name = _appNameController.text.trim();
    if (name.isEmpty) return;
    _regenerateIcon(name);
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
    _regenerateIcon(_appNameController.text.trim(), customPath: filePath);
  }

  /// Clears the custom icon and reverts to auto-generated.
  void _clearCustomIcon() {
    final appProv = context.read<AppProvider>();
    appProv.setCustomIconPath(null);
    _regenerateIcon(_appNameController.text.trim());
  }

  // ── Description generation via LLM ────────────────────────────────────────

  /// Generates a rich app description from the app name using the configured LLM.
  Future<void> _generateDescription(String appName, LLMConfig llmConfig) async {
    if (_descriptionLoading) return;
    setState(() => _descriptionLoading = true);

    try {
      final llm = LLMService(llmConfig);
      try {
        final prompt = '''
Based on the app name "$appName", write a concise app description for an Android developer to build.

Rules:
- 2-4 sentences maximum
- Describe what the app does, its main screens, and key features
- Be specific about UI elements and user interactions
- Do NOT include any greeting, preamble, or explanation — just the description
- Do NOT use quotes around the response
- Write as a direct instruction to the developer

Example for "Recipe Book":
A recipe book app with a home screen showing recipe cards with photos. Each card opens a detail page with ingredients, step-by-step instructions, and cook time. Include an add recipe screen with a form for title, ingredients, steps, and photo. Add a favorites screen showing bookmarked recipes with search functionality.
''';

        final response = await llm.generate(
          prompt,
          systemPrompt: 'You are a product designer. Output only the app description, nothing else.',
        );

        if (mounted) {
          // Clean up the response — remove any quotes, trim whitespace
          var cleaned = response.trim();
          if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
            cleaned = cleaned.substring(1, cleaned.length - 1);
          }
          _promptController.text = cleaned;
        }
      } finally {
        llm.dispose();
      }
    } catch (e) {
      // Silently fail — user can write their own description
    }

    if (mounted) setState(() => _descriptionLoading = false);
  }

  /// Manual regenerate button for description.
  void _onRegenerateDescription() {
    final appProv = context.read<AppProvider>();
    if (!appProv.isConfigured) return;
    final name = _appNameController.text.trim();
    if (name.isEmpty) return;
    _generateDescription(name, appProv.llmConfig);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
              // Icon preview + controls
              _buildIconSection(appProv),
              const SizedBox(width: 16),

              // App Name & Package stacked
              Expanded(
                child: Column(
                  children: [
                    _buildAppNameField(),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Package Name',
                      controller: _packageController,
                      hint: 'com.app.myapp',
                      icon: Icons.inventory_2,
                      onChanged: (v) => context.read<AppProvider>().setPackageName(v),
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

          // App description label + regenerate button
          Row(
            children: [
              const Text(
                'APP DESCRIPTION',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                ),
              ),
              const Spacer(),
              if (_descriptionLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                Tooltip(
                  message: appProv.isConfigured
                      ? 'Generate description from app name'
                      : 'Configure API key to auto-generate',
                  child: InkWell(
                    onTap: appProv.isConfigured ? _onRegenerateDescription : null,
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: appProv.isConfigured
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: appProv.isConfigured
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Generate',
                            style: TextStyle(
                              color: appProv.isConfigured
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Description text area
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
                      'Enter the app name above and tab out to auto-generate a description, '
                      'or write your own.\n\n'
                      'Example: A recipe book app with a home screen showing recipe cards, '
                      'a detail page for each recipe with ingredients and steps, '
                      'an add recipe screen with a form, and a favorites screen. '
                      'Use a warm color palette with orange accents...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintMaxLines: 6,
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

  // ── Icon section ──────────────────────────────────────────────────────────

  Widget _buildIconSection(AppProvider appProv) {
    final hasCustom = appProv.customIconPath != null;

    return Column(
      children: [
        const Text(
          'APP ICON',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        // Icon preview
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
                      ? Image.memory(
                          _iconPreviewBytes!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
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
        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Regenerate button (only when not using custom icon)
            if (!hasCustom)
              Tooltip(
                message: 'Regenerate icon',
                child: InkWell(
                  onTap: _onRegenerateIcon,
                  borderRadius: BorderRadius.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                  ),
                ),
              ),
            if (!hasCustom) const SizedBox(width: 4),
            // Import button
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
            // Clear custom icon
            if (hasCustom) ...[
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

  // ── App name field (with focus node) ──────────────────────────────────────

  Widget _buildAppNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'APP NAME',
          style: TextStyle(
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
            controller: _appNameController,
            focusNode: _appNameFocusNode,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
            onChanged: _onAppNameChanged,
            onSubmitted: (_) {
              // Also trigger on Enter key
              _appNameFocusNode.unfocus();
            },
            decoration: const InputDecoration(
              hintText: 'MyApp',
              prefixIcon: Icon(Icons.apps, size: 18, color: AppColors.onSurfaceVariant),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              fillColor: AppColors.surfaceContainerLowest,
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  // ── Generic field builder ─────────────────────────────────────────────────

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

  // ── Output directory picker ───────────────────────────────────────────────

  Widget _buildOutputDirPicker(AppProvider appProv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OUTPUT DIRECTORY',
          style: TextStyle(
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
                    if (dir != null && mounted) {
                      context.read<AppProvider>().setOutputDirectory(dir);
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

  // ── Auto-build row ────────────────────────────────────────────────────────

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

  // ── Generate ──────────────────────────────────────────────────────────────

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
