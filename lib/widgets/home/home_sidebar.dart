import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:dpad/dpad.dart';

class HomeNavItem {
  final IconData icon;
  final String label;
  const HomeNavItem({required this.icon, required this.label});
}

class HomeSidebar extends StatelessWidget {
  final List<HomeNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const HomeSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double kSidebarWidth = 64.0;

    return Container(
      width: kSidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.45),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Logo mark
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(items.length, (i) => _SidebarButton(
            icon: items[i].icon,
            selected: selectedIndex == i,
            tooltip: items[i].label,
            onTap: () => onTap(i),
          )),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onTap,
      builder: (context, isFocused, child) {
        return Tooltip(
          message: tooltip,
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isFocused || selected
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isFocused
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.6),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isFocused || selected
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.45),
            ),
          ),
        );
      },
    );
  }
}