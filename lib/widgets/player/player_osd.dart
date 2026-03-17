import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/iptv_channel.dart';
import 'clock_widget.dart';
import 'player_controls.dart';

class PlayerOSD extends StatelessWidget {
  final IPTVChannel channel;
  final DateTime now;
  final bool isMobile;
  final bool isLandscape;
  final int channelIndex;
  final int totalChannels;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onListToggle;

  const PlayerOSD({
    super.key,
    required this.channel,
    required this.now,
    required this.isMobile,
    required this.isLandscape,
    required this.channelIndex,
    required this.totalChannels,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
    required this.onListToggle,
  });

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 16.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.25, 0.72, 1.0],
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.88),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Row(
              children: [
                // Back button
                OSDIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const Spacer(),
                // Clock
                PlayerClock(now: now, isMobile: isMobile),
                const SizedBox(width: 12),
                // Channel list toggle
                OSDIconButton(
                  icon: Icons.list_rounded,
                  onTap: onListToggle,
                ),
              ],
            ),

            const Spacer(),

            // ── Bottom: channel info + nav ────────────────────────────────
            _ChannelInfoBar(
              channel: channel,
              channelIndex: channelIndex,
              totalChannels: totalChannels,
              isMobile: isMobile,
              onPrev: onPrev,
              onNext: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelInfoBar extends StatelessWidget {
  final IPTVChannel channel;
  final int channelIndex;
  final int totalChannels;
  final bool isMobile;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ChannelInfoBar({
    required this.channel,
    required this.channelIndex,
    required this.totalChannels,
    required this.isMobile,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const double kLogoSize = 64.0;
    const double kLogoSizeMobile = 48.0;

    final logoSize = isMobile ? kLogoSizeMobile : kLogoSize;
    final nameFontSize = isMobile ? 18.0 : 24.0;
    final chNumFontSize = isMobile ? 11.0 : 13.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Channel logo — no background, plain
        if (channel.logo != null)
          _ChannelLogo(url: channel.logo!, size: logoSize)
        else
          Icon(Icons.tv_rounded, size: logoSize * 0.65, color: Colors.white.withOpacity(0.5)),

        SizedBox(width: isMobile ? 12 : 18),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live badge + group
              Row(
                children: [
                  const LiveBadge(),
                  if (channel.group != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        channel.group!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Channel name
              Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              // Channel number + position
              Text(
                [
                  if (channel.number != null) 'CH ${channel.number.toString().padLeft(3, '0')}',
                  '${channelIndex + 1} / $totalChannels',
                ].join('  ·  '),
                style: TextStyle(
                  fontSize: chNumFontSize,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: isMobile ? 12 : 20),

        // Nav buttons
        Row(
          children: [
            NavButton(icon: Icons.keyboard_arrow_up_rounded, onTap: onPrev),
            SizedBox(width: isMobile ? 8 : 12),
            NavButton(icon: Icons.keyboard_arrow_down_rounded, onTap: onNext),
          ],
        ),
      ],
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  final String url;
  final double size;

  const _ChannelLogo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        memCacheWidth:  (size * 2).round(),
        memCacheHeight: (size * 2).round(),
        fadeInDuration: const Duration(milliseconds: 200),
        errorWidget: (_, __, ___) => Icon(
          Icons.tv_rounded,
          size: size * 0.65,
          color: Colors.white.withOpacity(0.5),
        ),
        placeholder: (_, __) => Icon(
          Icons.tv_rounded,
          size: size * 0.65,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
}
