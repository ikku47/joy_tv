import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:android_tv_text_field/native_textfield_tv.dart';
import 'package:dpad/dpad.dart';
import '../../theme/app_theme.dart';

class HomeSearchBar extends StatefulWidget {
  final NativeTextFieldController controller;
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
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  @override
  Widget build(BuildContext context) {
    const double kSearchHeight = 42.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: kSearchHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(widget.isFocused ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isFocused
              ? AppTheme.primaryColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: widget.isFocused
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          Expanded(
            child: NativeTextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              hint: 'Search channels, groups…',
              backgroundColor: Colors.transparent,
              textColor: Colors.white,
              onChanged: widget.onChanged,
              height: kSearchHeight,
            ),
          ),
          if (widget.query.isNotEmpty)
            DpadFocusable(
              onSelect: widget.onClear,
              builder: (context, isFocused, child) {
                return IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 16, 
                      color: isFocused 
                          ? AppTheme.primaryColor 
                          : Colors.white.withOpacity(0.5)),
                  onPressed: widget.onClear,
                  splashRadius: 16,
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}