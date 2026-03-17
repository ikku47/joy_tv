import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    const double kSearchHeight = 42.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: kSearchHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isFocused ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search channels, groups…',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: isFocused
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.4),
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  onPressed: onClear,
                  splashRadius: 16,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
