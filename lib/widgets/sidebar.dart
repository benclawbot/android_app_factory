import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSettingsTap;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _SidebarIcon(
            icon: Icons.auto_awesome,
            label: 'Generate',
            isSelected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          _SidebarIcon(
            icon: Icons.folder_open,
            label: 'Output',
            isSelected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
          const Spacer(),
          _SidebarIcon(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: false,
            onTap: onSettingsTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<_SidebarIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : _hovered
                      ? AppColors.card
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isSelected
                      ? AppColors.accent
                      : _hovered
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: widget.isSelected
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
