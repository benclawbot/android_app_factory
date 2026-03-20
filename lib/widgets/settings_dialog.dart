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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
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
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings, color: AppColors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // LLM Provider selection
            const Text(
              'LLM Provider',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ProviderCard(
                  label: 'MiniMax M2.7',
                  icon: Icons.auto_awesome,
                  color: AppColors.accent,
                  isSelected: _selectedProvider == LLMProvider.minimax,
                  onTap: () => setState(() => _selectedProvider = LLMProvider.minimax),
                ),
                const SizedBox(width: 12),
                _ProviderCard(
                  label: 'Claude Opus 4',
                  icon: Icons.psychology,
                  color: AppColors.purple,
                  isSelected: _selectedProvider == LLMProvider.anthropic,
                  onTap: () => setState(() => _selectedProvider = LLMProvider.anthropic),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // API Key
            const Text(
              'API Key',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: !_showKey,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'Consolas',
              ),
              decoration: InputDecoration(
                hintText: _selectedProvider == LLMProvider.minimax
                    ? 'Enter your MiniMax API key...'
                    : 'Enter your Anthropic API key...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showKey ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Custom Endpoint (optional)
            const Text(
              'Custom Endpoint (optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endpointController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: _selectedProvider == LLMProvider.minimax
                    ? 'https://api.minimax.io'
                    : 'https://api.anthropic.com',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use the default endpoint',
              style: TextStyle(
                color: AppColors.textMuted,
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
                      ? AppColors.card
                      : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.5)
                    : AppColors.border,
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected
                          ? widget.color
                          : AppColors.textSecondary,
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
