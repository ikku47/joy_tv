import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';

import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';
import '../../screens/player_screen.dart';

// ─── Column width constants ───────────────────────────────────────────────────
const double _kCategoryColW = 180.0;
const double _kChannelColW  = 280.0;

// ─── Item heights ─────────────────────────────────────────────────────────────
const double _kCatItemH = 44.0;
const double _kChItemH  = 52.0;

// ─── Main 3-column TV layout ─────────────────────────────────────────────────

class TvLiveLayout extends StatefulWidget {
  final List<String> categories;
  final List<IPTVChannel> channels;       // filtered by category / search
  final List<IPTVChannel> allChannels;    // full list for player
  final String selectedCategory;
  final bool isLoading;
  final String searchQuery;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onSearch;
  final VoidCallback onSearchClear;

  const TvLiveLayout({
    super.key,
    required this.categories,
    required this.channels,
    required this.allChannels,
    required this.selectedCategory,
    required this.isLoading,
    required this.searchQuery,
    required this.onCategorySelected,
    required this.onSearch,
    required this.onSearchClear,
  });

  @override
  State<TvLiveLayout> createState() => _TvLiveLayoutState();
}

class _TvLiveLayoutState extends State<TvLiveLayout> {
  // Active column: 0=categories, 1=channels, 2=preview(player)
  int _activeColumn = 1;
  int _focusedCategoryIndex = 0;
  int _focusedChannelIndex  = 0;

  final ScrollController _catScrollCtrl = ScrollController();
  final ScrollController _chScrollCtrl  = ScrollController();
  final FocusNode _catColFocus    = FocusNode(debugLabel: 'cat-col');
  final FocusNode _chColFocus     = FocusNode(debugLabel: 'ch-col');
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'tv-search');
  final NativeTextFieldController _searchCtrl = NativeTextFieldController();

  // ── Player state ─────────────────────────────────────────────────────────
  BetterPlayerController? _previewController;
  IPTVChannel? _loadedChannel;   // which channel is actually loaded in player
  Timer? _loadDebounce;          // debounce so rapid nav doesn't spam loads

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idx = widget.categories.indexOf(widget.selectedCategory);
      if (idx != -1) setState(() => _focusedCategoryIndex = idx);
      _chColFocus.requestFocus();
      // Load initial channel preview
      _schedulePreviewLoad();
    });
  }

  @override
  void didUpdateWidget(TvLiveLayout old) {
    super.didUpdateWidget(old);
    if (old.selectedCategory != widget.selectedCategory) {
      final idx = widget.categories.indexOf(widget.selectedCategory);
      if (idx != -1) {
        setState(() {
          _focusedCategoryIndex = idx;
          _focusedChannelIndex  = 0;
        });
        _scrollCatToIndex(idx);
        _scrollChToIndex(0);
        _schedulePreviewLoad();
      }
    }
    if (old.channels != widget.channels) {
      setState(() => _focusedChannelIndex = 0);
      _schedulePreviewLoad();
    }
  }

  @override
  void dispose() {
    _loadDebounce?.cancel();
    _previewController?.dispose();
    _catScrollCtrl.dispose();
    _chScrollCtrl.dispose();
    _catColFocus.dispose();
    _chColFocus.dispose();
    _searchFocusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _focusSearch() {
    setState(() => _activeColumn = 1);
    _searchFocusNode.requestFocus();
  }

  void _focusChannelList() {
    _chColFocus.requestFocus();
  }

  // ── Preview player ────────────────────────────────────────────────────────

  IPTVChannel? get _focusedChannel =>
      widget.channels.isNotEmpty && _focusedChannelIndex < widget.channels.length
          ? widget.channels[_focusedChannelIndex]
          : null;

  /// Debounced: wait 600 ms after last nav change before loading stream
  void _schedulePreviewLoad() {
    _loadDebounce?.cancel();
    _loadDebounce = Timer(const Duration(milliseconds: 600), _loadPreview);
  }

  void _loadPreview() {
    final ch = _focusedChannel;
    if (ch == null || ch == _loadedChannel) return;

    // Dispose old controller FIRST — reusing and calling setupDataSource() on an
    // already-initialized BetterPlayerController causes an IndexOutOfBoundsException
    // in the native plugin (known better_player_plus bug).
    final old = _previewController;
    _previewController = null;
    old?.dispose();

    setState(() => _loadedChannel = ch);

    // Create a fresh controller with the data source already set in the constructor.
    _previewController = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.cover,
        autoPlay: true,
        looping: true,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        ch.url,
        liveStream: true,
      ),
    );

    setState(() {});
  }

  // ── Scroll helpers ────────────────────────────────────────────────────────

  void _scrollCatToIndex(int i) {
    if (!_catScrollCtrl.hasClients) return;
    final offset = (i * _kCatItemH) - 100;
    _catScrollCtrl.animateTo(
      offset.clamp(0.0, _catScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _scrollChToIndex(int i) {
    if (!_chScrollCtrl.hasClients) return;
    final offset = (i * _kChItemH) - 120;
    _chScrollCtrl.animateTo(
      offset.clamp(0.0, _chScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ── Column navigation ─────────────────────────────────────────────────────

  void _onCatFocus(int index) {
    setState(() { _activeColumn = 0; _focusedCategoryIndex = index; });
    _scrollCatToIndex(index);
  }

  void _onCatSelected(int index) {
    widget.onCategorySelected(widget.categories[index]);
    setState(() { _activeColumn = 1; _focusedChannelIndex = 0; });
    _chColFocus.requestFocus();
  }

  void _onChFocus(int index) {
    setState(() { _activeColumn = 1; _focusedChannelIndex = index; });
    _scrollChToIndex(index);
    _schedulePreviewLoad();
  }

  /// Navigate to preview column → go fullscreen immediately
  void _onChNavigateRight() {
    _openFullscreen();
  }

  void _switchToCategories() {
    setState(() => _activeColumn = 0);
    _catColFocus.requestFocus();
  }

  void _switchToChannels() {
    setState(() => _activeColumn = 1);
    _chColFocus.requestFocus();
  }

  void _openFullscreen() {
    final ch = _focusedChannel;
    if (ch == null) return;

    // Pause preview before going fullscreen to free resources
    _previewController?.pause();

    final globalIndex = widget.allChannels.indexOf(ch);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channels: widget.allChannels,
          initialIndex: globalIndex >= 0 ? globalIndex : 0,
        ),
      ),
    ).then((_) {
      // Resume preview after returning
      if (mounted) _schedulePreviewLoad();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Col 1: Categories ───────────────────────────────────────────────
        SizedBox(
          width: _kCategoryColW,
          child: _CategoryColumn(
            focusNode: _catColFocus,
            categories: widget.categories,
            selectedCategory: widget.selectedCategory,
            focusedIndex: _focusedCategoryIndex,
            isActiveColumn: _activeColumn == 0,
            scrollController: _catScrollCtrl,
            onFocusRequested: _onCatFocus,
            onSelected: _onCatSelected,
            onNavigateRight: _switchToChannels,
          ),
        ),

        Container(width: 1, color: Colors.white.withOpacity(0.06)),

        // ── Col 2: Channels ─────────────────────────────────────────────────
        SizedBox(
          width: _kChannelColW,
          child: widget.isLoading
              ? const _ChannelLoadingPlaceholder()
              : _ChannelColumn(
                  focusNode: _chColFocus,
                  searchFocusNode: _searchFocusNode,
                  searchCtrl: _searchCtrl,
                  searchQuery: widget.searchQuery,
                  channels: widget.channels,
                  focusedIndex: _focusedChannelIndex,
                  isActiveColumn: _activeColumn == 1,
                  scrollController: _chScrollCtrl,
                  onFocusRequested: _onChFocus,
                  onSelected: (_) => _openFullscreen(),
                  onNavigateLeft: _switchToCategories,
                  onNavigateRight: _onChNavigateRight,
                  onSearch: widget.onSearch,
                  onSearchClear: widget.onSearchClear,
                  onSearchFocused: _focusSearch,
                  onSearchDone: _focusChannelList,
                ),
        ),

        Container(width: 1, color: Colors.white.withOpacity(0.06)),

        // ── Col 3: Live Preview ─────────────────────────────────────────────
        Expanded(
          child: _PreviewPanel(
            channel: _focusedChannel,
            previewController: _previewController,
            onWatch: _openFullscreen,
          ),
        ),
      ],
    );
  }
}

// ─── Category Column ──────────────────────────────────────────────────────────

class _CategoryColumn extends StatelessWidget {
  final FocusNode focusNode;
  final List<String> categories;
  final String selectedCategory;
  final int focusedIndex;
  final bool isActiveColumn;
  final ScrollController scrollController;
  final ValueChanged<int> onFocusRequested;
  final ValueChanged<int> onSelected;
  final VoidCallback onNavigateRight;

  const _CategoryColumn({
    required this.focusNode,
    required this.categories,
    required this.selectedCategory,
    required this.focusedIndex,
    required this.isActiveColumn,
    required this.scrollController,
    required this.onFocusRequested,
    required this.onSelected,
    required this.onNavigateRight,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown) {
          onFocusRequested((focusedIndex + 1).clamp(0, categories.length - 1));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          onFocusRequested((focusedIndex - 1).clamp(0, categories.length - 1));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          onNavigateRight();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
          onSelected(focusedIndex);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: categories.length,
              itemExtent: _kCatItemH,
              itemBuilder: (context, i) => _CategoryItem(
                label: categories[i],
                isSelected: categories[i] == selectedCategory,
                isFocused: isActiveColumn && i == focusedIndex,
                onTap: () => onSelected(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isFocused;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.isSelected,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _kCatItemH,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFocused
              ? AppTheme.primaryColor.withOpacity(0.18)
              : isSelected
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused ? AppTheme.primaryColor.withOpacity(0.7) : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isFocused || isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isFocused
                      ? Colors.white
                      : isSelected
                          ? AppTheme.primaryColor.withOpacity(0.9)
                          : Colors.white.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Channel Column ───────────────────────────────────────────────────────────

class _ChannelColumn extends StatelessWidget {
  final FocusNode focusNode;
  final FocusNode searchFocusNode;
  final NativeTextFieldController searchCtrl;
  final String searchQuery;
  final List<IPTVChannel> channels;
  final int focusedIndex;
  final bool isActiveColumn;
  final ScrollController scrollController;
  final ValueChanged<int> onFocusRequested;
  final ValueChanged<int> onSelected;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateRight;
  final ValueChanged<String> onSearch;
  final VoidCallback onSearchClear;
  final VoidCallback onSearchFocused;
  final VoidCallback onSearchDone;

  const _ChannelColumn({
    required this.focusNode,
    required this.searchFocusNode,
    required this.searchCtrl,
    required this.searchQuery,
    required this.channels,
    required this.focusedIndex,
    required this.isActiveColumn,
    required this.scrollController,
    required this.onFocusRequested,
    required this.onSelected,
    required this.onNavigateLeft,
    required this.onNavigateRight,
    required this.onSearch,
    required this.onSearchClear,
    required this.onSearchFocused,
    required this.onSearchDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search bar ──────────────────────────────────────────────────
        _TvSearchBar(
          focusNode: searchFocusNode,
          controller: searchCtrl,
          query: searchQuery,
          onSearch: onSearch,
          onClear: onSearchClear,
          onFocused: onSearchFocused,
          onDone: onSearchDone,
          onNavigateLeft: onNavigateLeft,
          onNavigateDown: () => onFocusRequested(0),
        ),

        // ── Header row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            children: [
              Text(
                'CHANNELS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${channels.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Channel list ────────────────────────────────────────────────
        Expanded(
          child: channels.isEmpty
              ? Center(
                  child: Text(
                    searchQuery.isNotEmpty ? 'No results for "$searchQuery"' : 'No channels',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                  ),
                )
              : Focus(
                  focusNode: focusNode,
                  onKeyEvent: (_, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;
                    final key = event.logicalKey;
                    if (key == LogicalKeyboardKey.arrowDown) {
                      onFocusRequested((focusedIndex + 1).clamp(0, channels.length - 1));
                      return KeyEventResult.handled;
                    }
                    if (key == LogicalKeyboardKey.arrowUp) {
                      if (focusedIndex == 0) {
                        onSearchFocused();
                        return KeyEventResult.handled;
                      }
                      onFocusRequested((focusedIndex - 1).clamp(0, channels.length - 1));
                      return KeyEventResult.handled;
                    }
                    if (key == LogicalKeyboardKey.arrowLeft) {
                      onNavigateLeft();
                      return KeyEventResult.handled;
                    }
                    if (key == LogicalKeyboardKey.arrowRight) {
                      onNavigateRight();
                      return KeyEventResult.handled;
                    }
                    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
                      onSelected(focusedIndex);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: channels.length,
                    itemExtent: _kChItemH,
                    itemBuilder: (context, i) => _ChannelRow(
                      channel: channels[i],
                      index: i,
                      isFocused: isActiveColumn && i == focusedIndex,
                      onTap: () => onSelected(i),
                      onHover: () => onFocusRequested(i),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final IPTVChannel channel;
  final int index;
  final bool isFocused;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _ChannelRow({
    required this.channel,
    required this.index,
    required this.isFocused,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: _kChItemH,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isFocused ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused ? AppTheme.primaryColor.withOpacity(0.55) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.22),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TvChannelLogo(url: channel.logo, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isFocused ? FontWeight.w600 : FontWeight.w500,
                        color: isFocused ? Colors.white : Colors.white.withOpacity(0.82),
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (channel.group != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        channel.group!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isFocused ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Channel Logo ─────────────────────────────────────────────────────────────

class _TvChannelLogo extends StatelessWidget {
  final String? url;
  final double size;
  const _TvChannelLogo({this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: url != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: url!,
                memCacheWidth: (size * 2).round(),
                memCacheHeight: (size * 2).round(),
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 150),
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
  Widget build(BuildContext context) =>
      Icon(Icons.tv_rounded, size: size * 0.45, color: Colors.white.withOpacity(0.18));
}

// ─── Preview Panel ────────────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final IPTVChannel? channel;
  final BetterPlayerController? previewController;
  final VoidCallback onWatch;

  const _PreviewPanel({
    required this.channel,
    required this.previewController,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final ch = channel;

    if (ch == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.live_tv_rounded, size: 40, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            Text(
              'Select a channel',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.22)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Embedded live player ────────────────────────────────────────────
        _EmbeddedPlayer(
          controller: previewController,
          channel: ch,
          onWatch: onWatch,
        ),

        // ── Channel info below player ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  ch.name,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Category tag
                if (ch.group != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.28),
                      ),
                    ),
                    child: Text(
                      ch.group!,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.primaryColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 12),

                if (ch.number != null)
                  _MetaRow(icon: Icons.tag_rounded, label: 'CH', value: '${ch.number}'),
                if (ch.tvgId != null)
                  _MetaRow(icon: Icons.fingerprint_rounded, label: 'ID', value: ch.tvgId!),

                const SizedBox(height: 16),

                // ── Fullscreen hint ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white.withOpacity(0.35)),
                      const SizedBox(width: 8),
                      Text(
                        'Press  →  or  OK  for fullscreen',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Embedded Player Widget ───────────────────────────────────────────────────

class _EmbeddedPlayer extends StatefulWidget {
  final BetterPlayerController? controller;
  final IPTVChannel channel;
  final VoidCallback onWatch;

  const _EmbeddedPlayer({
    required this.controller,
    required this.channel,
    required this.onWatch,
  });

  @override
  State<_EmbeddedPlayer> createState() => _EmbeddedPlayerState();
}

class _EmbeddedPlayerState extends State<_EmbeddedPlayer> {
  bool _isBuffering = true;
  bool _hasError    = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addEventsListener(_onEvent);
  }

  @override
  void didUpdateWidget(_EmbeddedPlayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeEventsListener(_onEvent);
      widget.controller?.addEventsListener(_onEvent);
      setState(() { _isBuffering = true; _hasError = false; });
    }
    if (old.channel != widget.channel) {
      setState(() { _isBuffering = true; _hasError = false; });
    }
  }

  @override
  void dispose() {
    widget.controller?.removeEventsListener(_onEvent);
    super.dispose();
  }

  void _onEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
      case BetterPlayerEventType.play:
      case BetterPlayerEventType.bufferingEnd:
        if (_isBuffering || _hasError) setState(() { _isBuffering = false; _hasError = false; });
        break;
      case BetterPlayerEventType.bufferingStart:
        if (!_isBuffering) setState(() => _isBuffering = true);
        break;
      case BetterPlayerEventType.exception:
        setState(() { _isBuffering = false; _hasError = true; });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 16:9 aspect ratio for the player area
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: widget.onWatch,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video ───────────────────────────────────────────────────
              if (widget.controller != null && !_hasError)
                BetterPlayer(controller: widget.controller!),

              // ── Error fallback ───────────────────────────────────────────
              if (_hasError)
                _ErrorPlaceholder(channel: widget.channel),

              // ── Buffering indicator ──────────────────────────────────────
              if (_isBuffering && !_hasError)
                _BufferingOverlay(channel: widget.channel),

              // ── Live badge + tap overlay ────────────────────────────────
              if (!_isBuffering && !_hasError)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _LiveBadge(),
                ),

              // ── Fullscreen click area (entire player) ───────────────────
              Positioned.fill(child: Container(color: Colors.transparent)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live badge ────────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buffering placeholder ─────────────────────────────────────────────────────
class _BufferingOverlay extends StatelessWidget {
  final IPTVChannel channel;
  const _BufferingOverlay({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (channel.logo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: channel.logo!,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Loading stream…',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error placeholder ─────────────────────────────────────────────────────────
class _ErrorPlaceholder extends StatelessWidget {
  final IPTVChannel channel;
  const _ErrorPlaceholder({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off_rounded, size: 32, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 8),
            Text(
              'Preview unavailable',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.25)),
          const SizedBox(width: 6),
          Text(
            '$label  ',
            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.28), fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.65)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TV Search Bar ────────────────────────────────────────────────────────────

class _TvSearchBar extends StatefulWidget {
  final FocusNode focusNode;
  final NativeTextFieldController controller;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final VoidCallback onFocused;
  final VoidCallback onDone;
  final VoidCallback onNavigateLeft;
  final VoidCallback onNavigateDown;

  const _TvSearchBar({
    required this.focusNode,
    required this.controller,
    required this.query,
    required this.onSearch,
    required this.onClear,
    required this.onFocused,
    required this.onDone,
    required this.onNavigateLeft,
    required this.onNavigateDown,
  });

  @override
  State<_TvSearchBar> createState() => _TvSearchBarState();
}

class _TvSearchBarState extends State<_TvSearchBar> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    // Attach DPad key handler directly on the FocusNode.
    // This avoids duplicating the FocusNode inside both a Focus widget
    // and NativeTextField (same node can't be ancestor of itself).
    widget.focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void didUpdateWidget(_TvSearchBar old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocusChange);
      old.focusNode.onKeyEvent = null;
      widget.focusNode.addListener(_onFocusChange);
      widget.focusNode.onKeyEvent = _handleKeyEvent;
    }
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.focusNode.onKeyEvent = null;
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onDone();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && widget.controller.text.isEmpty) {
      widget.onNavigateLeft();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      widget.controller.clear();
      widget.onClear();
      widget.onDone();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _isFocused) {
      setState(() => _isFocused = focused);
      if (focused) widget.onFocused();
    }
  }

  void _onTextChange() {
    widget.onSearch(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // No outer Focus() widget — the FocusNode lives only inside NativeTextField.
    // Key handling is wired via focusNode.onKeyEvent in initState.
    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        margin: const EdgeInsets.fromLTRB(8, 10, 8, 0),
        decoration: BoxDecoration(
          color: _isFocused
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFocused
                ? AppTheme.primaryColor.withOpacity(0.65)
                : Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.search_rounded,
                size: 16,
                color: _isFocused
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.35),
              ),
            ),
            Expanded(
              child: NativeTextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                hint: 'Search channels…',
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
                onChanged: widget.onSearch,
                height: 38,
              ),
            ),
            if (widget.query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onClear();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Channel list loading skeleton ───────────────────────────────────────────
class _ChannelLoadingPlaceholder extends StatelessWidget {
  const _ChannelLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 16),
      itemCount: 12,
      itemExtent: _kChItemH,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
