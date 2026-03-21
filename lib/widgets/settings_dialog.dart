import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/llm_config.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _endpointController;
  late LLMProvider _selectedProvider;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    final appProv = context.read<AppProvider>();
    _apiKeyController = TextEditingController(text: appProv.llmConfig.apiKey);
    _endpointController =
        TextEditingController(text: appProv.llmConfig.customEndpoint ?? '');
    _selectedProvider = appProv.llmConfig.provider;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.settings, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.01,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // LLM Provider selection
            Text(
              'LLM Provider'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ProviderCard(
                  label: 'MiniMax M2.7',
                  icon: Icons.auto_awesome,
                  color: AppColors.primary,
                  isSelected: _selectedProvider == LLMProvider.minimax,
                  onTap: () => setState(() => _selectedProvider = LLMProvider.minimax),
                ),
                const SizedBox(width: 12),
                _ProviderCard(
                  label: 'Claude Opus 4',
                  icon: Icons.psychology,
                  color: AppColors.surfaceContainerHighest,
                  isSelected: _selectedProvider == LLMProvider.anthropic,
                  onTap: () => setState(() => _selectedProvider = LLMProvider.anthropic),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // API Key
            Text(
              'API Key'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: !_showKey,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontFamily: 'Consolas',
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: _selectedProvider == LLMProvider.minimax
                    ? 'Enter your MiniMax API key...'
                    : 'Enter your Anthropic API key...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showKey ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
                fillColor: AppColors.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 20),

            // Custom Endpoint (optional)
            Text(
              'Custom Endpoint (optional)'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endpointController,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: _selectedProvider == LLMProvider.minimax
                    ? 'https://api.minimax.io'
                    : 'https://api.anthropic.com',
                fillColor: AppColors.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use the default endpoint',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final appProv = context.read<AppProvider>();
    appProv.setLLMProvider(_selectedProvider);
    appProv.setApiKey(_apiKeyController.text.trim());
    final endpoint = _endpointController.text.trim();
    appProv.setCustomEndpoint(endpoint.isEmpty ? null : endpoint);
    Navigator.pop(context);
  }
}

class _ProviderCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withValues(alpha: 0.12)
                  : _hovered
                      ? AppColors.surfaceVariant
                      : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.zero,
              border: widget.isSelected
                  ? Border.all(color: widget.color.withValues(alpha: 0.5), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.isSelected ? widget.color : AppColors.onSurfaceVariant, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected ? widget.color : AppColors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Icon(Icons.check_circle, color: widget.color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
