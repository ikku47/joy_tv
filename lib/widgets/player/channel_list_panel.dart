import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';

class ChannelListPanel extends StatelessWidget {
  final List<IPTVChannel> channels;
  final int currentIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const ChannelListPanel({
    super.key,
    required this.channels,
    required this.currentIndex,
    required this.scrollController,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final panelWidth = isMobile ? MediaQuery.of(context).size.width * 0.72 : 280.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E).withOpacity(0.97),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Column(
        children: [
          // Panel header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Channels',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  DpadFocusable(
                    onSelect: onClose,
                    builder: (context, isFocused, child) {
                      return GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isFocused 
                                ? AppTheme.primaryColor.withOpacity(0.2) 
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: isFocused 
                                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5)) 
                                : null,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: isFocused 
                                ? AppTheme.primaryColor 
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          // List
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: channels.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) => _ChannelListItem(
                channel: channels[index],
                isSelected: index == currentIndex,
                onTap: () => onSelect(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelListItem extends StatefulWidget {
  final IPTVChannel channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelListItem({
    required this.channel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChannelListItem> createState() => _ChannelListItemState();
}

class _ChannelListItemState extends State<_ChannelListItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: widget.onTap,
      builder: (context, isFocused, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: widget.isSelected || isFocused
                  ? AppTheme.primaryColor.withOpacity(isFocused ? 0.22 : 0.15)
                  : _pressed
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryColor.withOpacity(0.7)
                    : widget.isSelected
                        ? AppTheme.primaryColor.withOpacity(0.4)
                        : Colors.transparent,
                width: isFocused ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  // Logo
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: widget.channel.logo != null
                        ? CachedNetworkImage(
                            imageUrl: widget.channel.logo!,
                            fit: BoxFit.contain,
                            memCacheWidth: 68,
                            memCacheHeight: 68,
                            fadeInDuration: const Duration(milliseconds: 150),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.tv_rounded,
                              size: 18,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            placeholder: (_, __) => const SizedBox.shrink(),
                          )
                        : Icon(
                            Icons.tv_rounded,
                            size: 18,
                            color: Colors.white.withOpacity(0.25),
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Name + group
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
                            fontSize: 13,
                            fontWeight: widget.isSelected || isFocused
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.isSelected || isFocused
                                ? (isFocused ? Colors.white : AppTheme.primaryColor)
                                : Colors.white.withOpacity(0.85),
                          ),
                        ),
                        if (widget.channel.group != null)
                          Text(
                            widget.channel.group!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isFocused 
                                  ? Colors.white.withOpacity(0.5) 
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Playing indicator
                  if (widget.isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
