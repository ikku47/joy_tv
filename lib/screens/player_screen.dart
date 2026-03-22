import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/iptv_channel.dart';
import '../services/device_profile_service.dart';
import '../utils/log_util.dart';
import '../utils/orientation_policy.dart';
import '../widgets/player/buffering_indicator.dart';
import '../widgets/player/error_overlay.dart';
import '../widgets/player/player_osd.dart';
import '../widgets/player/channel_list_panel.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kOverlayDuration  = Duration(seconds: 5);
const _kFadeDuration     = Duration(milliseconds: 280);

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
  bool _isHandheldDevice = true;
  bool _orientationProfileApplied = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orientationProfileApplied) return;
    _orientationProfileApplied = true;
    _configureOrientationProfile();
  }

  Future<void> _configureOrientationProfile() async {
    final fallbackHandheld = OrientationPolicy.isHandheld(context);
    _isHandheldDevice = fallbackHandheld;

    final isTv = await DeviceProfileService.isTvDevice();
    if (!mounted) return;
    _isHandheldDevice = isTv ? false : fallbackHandheld;

    logI(
      'PlayerScreen profile: isTv=$isTv fallbackHandheld=$fallbackHandheld finalHandheld=$_isHandheldDevice',
      tag: 'Orientation',
    );
    OrientationPolicy.enterPlayback(source: 'PlayerScreen');
  }

  @override
  void dispose() {
    OrientationPolicy.restoreAfterPlayback(
      isHandheldDevice: _isHandheldDevice,
      source: 'PlayerScreen',
    );
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
                const BufferingIndicator(),

              // ── Error ────────────────────────────────────────────────────
              if (_errorMessage != null)
                ErrorOverlay(
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
                    child: PlayerOSD(
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
                    child: ChannelListPanel(
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
