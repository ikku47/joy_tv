import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../theme/app_theme.dart';

class HomeSearchBar extends StatefulWidget {
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
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode;
    // Add listener to show keyboard when focused on TV
    _internalFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_internalFocusNode.hasFocus) {
      // Ensure keyboard is shown on TV devices
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _internalFocusNode.hasFocus) {
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    }
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double kSearchHeight = 42.0;

    return Focus(
      onKey: (node, event) {
        // Allow D-pad to focus the search bar
        if (event.isKeyPressed(LogicalKeyboardKey.select) ||
            event.isKeyPressed(LogicalKeyboardKey.enter)) {
          _internalFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
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
        child: TextField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          textAlignVertical: TextAlignVertical.center,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          enableInteractiveSelection: true,
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
              color: widget.isFocused
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.4),
            ),
            suffixIcon: widget.query.isNotEmpty
                ? Focus(
                    onKey: (node, event) {
                      if (event.isKeyPressed(LogicalKeyboardKey.select) ||
                          event.isKeyPressed(LogicalKeyboardKey.enter)) {
                        widget.onClear();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: Colors.white.withOpacity(0.5)),
                      onPressed: widget.onClear,
                      splashRadius: 16,
                    ),
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}