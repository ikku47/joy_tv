import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';
import '../../screens/player_screen.dart';

class ChannelCard extends StatefulWidget {
  final IPTVChannel channel;
  final int index;
  final bool isMobile;
  final List<IPTVChannel> allChannels;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.index,
    required this.isMobile,
    required this.allChannels,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _focused = false;
  bool _pressed = false;

  void _navigate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channels: widget.allChannels,
          initialIndex: widget.index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kCardRadiusMobile = 10.0;
    const double kCardRadiusDesktop = 12.0;

    final r = widget.isMobile ? kCardRadiusMobile : kCardRadiusDesktop;
    final logoSize = widget.isMobile ? 34.0 : 42.0;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          _navigate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); _navigate(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_focused ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _focused
                  ? AppTheme.primaryColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                color: _focused
                    ? AppTheme.primaryColor.withOpacity(0.7)
                    : Colors.white.withOpacity(0.08),
                width: _focused ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Logo
                  _ChannelLogo(
                    url: widget.channel.logo,
                    size: logoSize,
                    radius: r * 0.6,
                    focused: _focused,
                  ),
                  const SizedBox(width: 9),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.isMobile ? 11.5 : 13,
                            fontWeight: FontWeight.w600,
                            color: _focused
                                ? AppTheme.primaryColor
                                : Colors.white.withOpacity(0.92),
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (widget.channel.group != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.channel.group!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.isMobile ? 9.5 : 10.5,
                              color: _focused
                                  ? AppTheme.primaryColor.withOpacity(0.65)
                                  : Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final bool focused;

  const _ChannelLogo({
    this.url,
    required this.size,
    required this.radius,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(focused ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: url != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: CachedNetworkImage(
                imageUrl: url!,
                memCacheWidth:  (size * 2).round(),
                memCacheHeight: (size * 2).round(),
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => _FallbackIcon(size: size),
                errorWidget: (_, __, ___) => _FallbackIcon(size: size),
              ),
            )
          : _FallbackIcon(size: size),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final double size;
  const _FallbackIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.tv_rounded,
      size: size * 0.45,
      color: Colors.white.withOpacity(0.25),
    );
  }
}
