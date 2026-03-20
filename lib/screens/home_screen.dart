import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/console_panel.dart';
import '../widgets/file_tree_panel.dart';
import '../widgets/prompt_panel.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
            onSettingsTap: () => _showSettings(context),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(context),
                const Divider(height: 1, color: AppColors.border),
                // Body
                Expanded(
                  child: _selectedTab == 0
                      ? _buildGeneratorView()
                      : _buildOutputView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final genProv = context.watch<GenerationProvider>();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          const Icon(Icons.android, color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Android App Factory',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'MVP',
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // LLM indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  appProv.isConfigured ? Icons.check_circle : Icons.warning,
                  size: 14,
                  color: appProv.isConfigured
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  appProv.llmConfig.displayName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (genProv.isGenerating) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratorView() {
    return Row(
      children: [
        // Prompt panel (left)
        const Expanded(
          flex: 5,
          child: PromptPanel(),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        // Console panel (right)
        const Expanded(
          flex: 4,
          child: ConsolePanel(),
        ),
      ],
    );
  }

  Widget _buildOutputView() {
    return const FileTreePanel();
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }
}
