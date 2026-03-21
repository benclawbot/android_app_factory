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
        color: AppColors.surfaceContainerLow, // Tonal separation, no border
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
            icon: Icons.history,
            label: 'History',
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
              // Active state uses primary accent sparingly
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : _hovered
                      ? AppColors.surfaceVariant
                      : Colors.transparent,
              // 0px radius - Pro IDE
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isSelected
                      ? AppColors.primary
                      : _hovered
                          ? AppColors.textPrimary
                          : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.02,
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
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
