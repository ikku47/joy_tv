import 'package:flutter/material.dart';
import '../../models/iptv_channel.dart';
import 'channel_card.dart';

class ChannelGrid extends StatelessWidget {
  final List<IPTVChannel> channels;
  final bool isMobile;
  final ScrollController scrollController;
  final double hPad;

  const ChannelGrid({
    super.key,
    required this.channels,
    required this.isMobile,
    required this.scrollController,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
      // Performance knobs
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 200,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? 180 : 200,
        childAspectRatio: isMobile ? 2.0 : 2.6,
        crossAxisSpacing: isMobile ? 8 : 10,
        mainAxisSpacing: isMobile ? 8 : 10,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) => ChannelCard(
        channel: channels[index],
        index: index,
        isMobile: isMobile,
        allChannels: channels,
      ),
    );
  }
}
