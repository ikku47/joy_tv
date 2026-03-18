import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final bool isMobile;
  final int navIndex;
  final List<IPTVPlaylistSource> sources;
  final String? selectedSourceId;
  final VoidCallback onSourcePick;
  final double hPad;

  const HomeHeader({
    super.key,
    required this.isMobile,
    required this.navIndex,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourcePick,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['Live TV', 'Movies', 'Series', 'Favorites', 'Settings'];
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 54 : 36, hPad, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            navIndex < titles.length ? titles[navIndex] : '',
            style: TextStyle(
              fontSize: isMobile ? 22 : 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (navIndex == 0 && sources.isNotEmpty)
            _SourcePill(
              label: sources.firstWhere(
                (s) => s.id == selectedSourceId,
                orElse: () => sources.first,
              ).name,
              onTap: onSourcePick,
            ),
        ],
      ),
    );
  }
}

class _SourcePill extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SourcePill({required this.label, required this.onTap});

  @override
  State<_SourcePill> createState() => _SourcePillState();
}

class _SourcePillState extends State<_SourcePill> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.select) ||
            event.isKeyPressed(LogicalKeyboardKey.enter) ||
            event.isKeyPressed(LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? AppTheme.primaryColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.playlist_play_rounded,
                  size: 16,
                  color: _focused ? AppTheme.primaryColor : AppTheme.primaryColor),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _focused ? FontWeight.w600 : FontWeight.w400,
                    color: _focused
                        ? AppTheme.primaryColor
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: _focused
                      ? AppTheme.primaryColor.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}