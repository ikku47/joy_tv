import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/iptv_channel.dart';
import '../theme/app_theme.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kOverlayDuration  = Duration(seconds: 5);
const _kFadeDuration     = Duration(milliseconds: 280);
const _kLogoSize         = 64.0;
const _kLogoSizeMobile   = 48.0;

// ─── Player Screen ────────────────────────────────────────────────────────────

class PlayerScreen extends StatefulWidget {
  final List<IPTVChannel> channels;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.channels,
    required this.initialIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  // Player
  late BetterPlayerController _playerController;
  late int _currentIndex;
  bool _isLoading = true;
  String? _errorMessage;

  // OSD
  bool _showOverlay = true;
  Timer? _overlayTimer;

  // Clock
  late DateTime _now;
  late Timer _clockTimer;

  // Focus / keyboard
  final FocusNode _focusNode = FocusNode();

  // Channel list panel
  bool _showChannelList = false;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _now = DateTime.now();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _now = DateTime.now()); },
    );

    _initPlayer();
    _resetOverlayTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Scroll channel list to current item
      _scrollToCurrentChannel();
    });
  }

  @override
  void dispose() {
    _playerController.dispose();
    _overlayTimer?.cancel();
    _clockTimer.cancel();
    _focusNode.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  IPTVChannel get _currentChannel => widget.channels[_currentIndex];

  // ── Player ─────────────────────────────────────────────────────────────────

  void _initPlayer() {
    _playerController = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        showPlaceholderUntilPlay: true,
        placeholder: SizedBox.shrink(),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
    );

    _playerController.addEventsListener(_onPlayerEvent);
    _loadSource();
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.exception:
        setState(() {
          _isLoading = false;
          _errorMessage = event.parameters?['exception']?.toString()
              ?? 'Stream could not be loaded.';
        });
        break;
      case BetterPlayerEventType.initialized:
        setState(() { _isLoading = false; _errorMessage = null; });
        break;
      case BetterPlayerEventType.bufferingStart:
        setState(() => _isLoading = true);
        break;
      case BetterPlayerEventType.bufferingEnd:
      case BetterPlayerEventType.play:
        setState(() => _isLoading = false);
        break;
      default:
        break;
    }
  }

  void _loadSource() {
    _playerController.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _currentChannel.url,
        liveStream: true,
      ),
    );
  }

  void _switchChannel(int index) {
    if (index < 0 || index >= widget.channels.length) return;
    setState(() {
      _currentIndex = index;
      _isLoading = true;
      _errorMessage = null;
      _showChannelList = false;
    });
    _loadSource();
    _resetOverlayTimer();
    _scrollToCurrentChannel();
  }

  void _nextChannel() =>
      _switchChannel((_currentIndex + 1) % widget.channels.length);

  void _prevChannel() =>
      _switchChannel((_currentIndex - 1 + widget.channels.length) % widget.channels.length);

  // ── Overlay timer ──────────────────────────────────────────────────────────

  void _resetOverlayTimer() {
    _overlayTimer?.cancel();
    if (!mounted) return;
    setState(() => _showOverlay = true);
    _overlayTimer = Timer(_kOverlayDuration, () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _toggleOverlay() {
    if (_showOverlay) {
      _overlayTimer?.cancel();
      setState(() => _showOverlay = false);
    } else {
      _resetOverlayTimer();
    }
  }

  // ── Channel list scroll ────────────────────────────────────────────────────

  void _scrollToCurrentChannel() {
    if (!_listScrollController.hasClients) return;
    const itemHeight = 56.0;
    final offset = (_currentIndex * itemHeight)
        - (_listScrollController.position.viewportDimension / 2)
        + (itemHeight / 2);
    _listScrollController.animateTo(
      offset.clamp(0.0, _listScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp    || key == LogicalKeyboardKey.channelUp)   _prevChannel();
    else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) _nextChannel();
    else if (key == LogicalKeyboardKey.arrowLeft)  Navigator.of(context).maybePop();
    else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter)       _resetOverlayTimer();
    else if (key == LogicalKeyboardKey.keyL)       setState(() => _showChannelList = !_showChannelList);
    else                                            _resetOverlayTimer();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _errorMessage == null ? _toggleOverlay : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video ────────────────────────────────────────────────────
              Center(
                child: BetterPlayer(controller: _playerController),
              ),

              // ── Buffering spinner ────────────────────────────────────────
              if (_isLoading && _errorMessage == null)
                const _BufferingIndicator(),

              // ── Error ────────────────────────────────────────────────────
              if (_errorMessage != null)
                _ErrorOverlay(
                  message: _errorMessage!,
                  onBack: () => Navigator.of(context).pop(),
                  onRetry: () {
                    setState(() { _errorMessage = null; _isLoading = true; });
                    _playerController.retryDataSource();
                  },
                ),

              // ── OSD ──────────────────────────────────────────────────────
              if (_errorMessage == null)
                AnimatedOpacity(
                  opacity: _showOverlay ? 1.0 : 0.0,
                  duration: _kFadeDuration,
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: _OSD(
                      channel: _currentChannel,
                      now: _now,
                      isMobile: isMobile,
                      isLandscape: isLandscape,
                      channelIndex: _currentIndex,
                      totalChannels: widget.channels.length,
                      onBack: () => Navigator.of(context).pop(),
                      onPrev: _prevChannel,
                      onNext: _nextChannel,
                      onListToggle: () => setState(() {
                        _showChannelList = !_showChannelList;
                        _resetOverlayTimer();
                      }),
                    ),
                  ),
                ),

              // ── Channel list panel ────────────────────────────────────────
              AnimatedSlide(
                offset: _showChannelList ? Offset.zero : const Offset(1, 0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _showChannelList ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _ChannelListPanel(
                      channels: widget.channels,
                      currentIndex: _currentIndex,
                      scrollController: _listScrollController,
                      onSelect: _switchChannel,
                      onClose: () => setState(() => _showChannelList = false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── OSD ──────────────────────────────────────────────────────────────────────

class _OSD extends StatelessWidget {
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

  const _OSD({
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
                _OSDIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
                const Spacer(),
                // Clock
                _ClockWidget(now: now, isMobile: isMobile),
                const SizedBox(width: 12),
                // Channel list toggle
                _OSDIconButton(
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

// ─── Channel Info Bar ─────────────────────────────────────────────────────────

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
    final logoSize = isMobile ? _kLogoSizeMobile : _kLogoSize;
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
                  _LiveBadge(),
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
            _NavButton(icon: Icons.keyboard_arrow_up_rounded, onTap: onPrev),
            SizedBox(width: isMobile ? 8 : 12),
            _NavButton(icon: Icons.keyboard_arrow_down_rounded, onTap: onNext),
          ],
        ),
      ],
    );
  }
}

// ─── Channel Logo ─────────────────────────────────────────────────────────────

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

// ─── Live Badge ───────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clock Widget ─────────────────────────────────────────────────────────────

class _ClockWidget extends StatelessWidget {
  final DateTime now;
  final bool isMobile;

  const _ClockWidget({required this.now, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(now),
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          DateFormat('EEE, dd MMM').format(now),
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── OSD Icon Button ──────────────────────────────────────────────────────────

class _OSDIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OSDIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_pressed ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(widget.icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Buffering Indicator ──────────────────────────────────────────────────────

class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading stream…',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Overlay ────────────────────────────────────────────────────────────

class _ErrorOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _ErrorOverlay({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 380),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 28 : 0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stream Unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ErrorButton(
                          label: 'Go Back',
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack,
                          filled: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ErrorButton(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          onTap: onRetry,
                          filled: true,
                        ),
                      ),
                    ],
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

class _ErrorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _ErrorButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  State<_ErrorButton> createState() => _ErrorButtonState();
}

class _ErrorButtonState extends State<_ErrorButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: widget.filled
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: widget.filled
                ? null
                : Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.filled ? Colors.white : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.filled ? Colors.white : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Channel List Panel ───────────────────────────────────────────────────────

class _ChannelListPanel extends StatelessWidget {
  final List<IPTVChannel> channels;
  final int currentIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const _ChannelListPanel({
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
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
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
              // Performance: disable keepalives for large lists
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : _pressed
                  ? Colors.white.withOpacity(0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.primaryColor.withOpacity(0.4)
                : Colors.transparent,
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
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: widget.isSelected
                            ? AppTheme.primaryColor
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
                          color: Colors.white.withOpacity(0.3),
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
  }
}