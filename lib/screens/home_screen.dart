import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/iptv_channel.dart';
import '../services/playlist_cache_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kSidebarWidth = 64.0;
const _kMobileBreak  = 600.0;
const _kCardRadiusMobile = 10.0;
const _kCardRadiusDesktop = 12.0;
const double _kSearchHeight = 42.0;

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PlaylistCacheService _cacheService = PlaylistCacheService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<IPTVPlaylistSource> _sources = [];
  List<IPTVChannel> _channels = [];
  List<IPTVChannel> _filteredChannels = [];

  bool _isLoading = true;
  bool _isSearchFocused = false;
  String? _selectedSourceId;
  int _selectedNavIndex = 0;
  String _searchQuery = '';

  // Nav items shared across sidebar / bottom bar
  static const _navItems = [
    _NavItem(icon: Icons.live_tv_rounded,   label: 'Live'),
    _NavItem(icon: Icons.movie_rounded,     label: 'Movies'),
    _NavItem(icon: Icons.tv_rounded,        label: 'Series'),
    _NavItem(icon: Icons.star_rounded,      label: 'Favorites'),
    _NavItem(icon: Icons.settings_rounded,  label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    final focused = _searchFocusNode.hasFocus;
    if (focused != _isSearchFocused) {
      setState(() => _isSearchFocused = focused);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  void _filterChannels() {
    if (_searchQuery.isEmpty) {
      _filteredChannels = _channels;
    } else {
      _filteredChannels = _channels.where((ch) {
        return ch.name.toLowerCase().contains(_searchQuery) ||
            (ch.group?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
  }

  Future<void> _loadInitialData() async {
    final sources = await _cacheService.getSources();
    if (!mounted) return;
    setState(() {
      _sources = sources;
      if (sources.isNotEmpty) _selectedSourceId = sources.first.id;
    });
    if (sources.isNotEmpty) await _loadChannels(sources.first);
  }

  Future<void> _loadChannels(IPTVPlaylistSource source) async {
    setState(() => _isLoading = true);
    final channels = await _cacheService.fetchPlaylist(source);
    if (!mounted) return;
    setState(() {
      _channels = channels;
      _filterChannels();
      _isLoading = false;
    });
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _kMobileBreak;
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Row(
            children: [
              if (!isMobile) _Sidebar(
                items: _navItems,
                selectedIndex: _selectedNavIndex,
                onTap: _onNavTap,
              ),
              Expanded(child: _buildBody(isMobile)),
            ],
          ),
          bottomNavigationBar: isMobile ? _buildBottomBar() : null,
        );
      },
    );
  }

  // ── Bottom bar (mobile) ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_navItems.length - 1, (i) {  // hide Settings in bottom bar
              final item = _navItems[i];
              final selected = _selectedNavIndex == i;
              return Expanded(
                child: _BottomBarButton(
                  icon: item.icon,
                  label: item.label,
                  selected: selected,
                  onTap: () => _onNavTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Main body ──────────────────────────────────────────────────────────────

  Widget _buildBody(bool isMobile) {
    final hPad = isMobile ? 16.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          isMobile: isMobile,
          navIndex: _selectedNavIndex,
          sources: _sources,
          selectedSourceId: _selectedSourceId,
          onSourcePick: _showPlaylistPicker,
          hPad: hPad,
        ),

        if (_selectedNavIndex == 0) ...[
          // Search
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
            child: _SearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isFocused: _isSearchFocused,
              query: _searchQuery,
              onChanged: (v) => setState(() {
                _searchQuery = v.toLowerCase();
                _filterChannels();
              }),
              onClear: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
                _filterChannels();
              }),
            ),
          ),

          // Count label
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
              child: Text(
                '${_filteredChannels.length} channels',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ),

          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: _LoadingIndicator())
                : _filteredChannels.isEmpty
                    ? _EmptyState(query: _searchQuery)
                    : _ChannelGrid(
                        channels: _filteredChannels,
                        isMobile: isMobile,
                        scrollController: _scrollController,
                        hPad: hPad,
                      ),
          ),
        ] else
          const Expanded(child: Center(child: _ComingSoon())),
      ],
    );
  }

  // ── Playlist picker ────────────────────────────────────────────────────────

  void _showPlaylistPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlaylistPickerSheet(
        sources: _sources,
        selectedId: _selectedSourceId,
        onSelect: (source) {
          setState(() => _selectedSourceId = source.id);
          _loadChannels(source);
        },
      ),
    );
  }
}

// ─── Sidebar (desktop/TV) ─────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.45),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Logo mark
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(items.length, (i) => _SidebarButton(
            icon: items[i].icon,
            selected: selectedIndex == i,
            tooltip: items[i].label,
            onTap: () => onTap(i),
          )),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isMobile;
  final int navIndex;
  final List<IPTVPlaylistSource> sources;
  final String? selectedSourceId;
  final VoidCallback onSourcePick;
  final double hPad;

  const _Header({
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

class _SourcePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SourcePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_play_rounded,
                size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _kSearchHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isFocused ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
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
            color: isFocused
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.4),
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  onPressed: onClear,
                  splashRadius: 16,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── Channel Grid ─────────────────────────────────────────────────────────────

class _ChannelGrid extends StatelessWidget {
  final List<IPTVChannel> channels;
  final bool isMobile;
  final ScrollController scrollController;
  final double hPad;

  const _ChannelGrid({
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

// ─── Channel Card ─────────────────────────────────────────────────────────────

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
    final r = widget.isMobile ? _kCardRadiusMobile : _kCardRadiusDesktop;
    final logoSize = widget.isMobile ? 34.0 : 42.0;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
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

// ─── Channel Logo ─────────────────────────────────────────────────────────────

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

// ─── Playlist Picker Sheet ────────────────────────────────────────────────────

class _PlaylistPickerSheet extends StatelessWidget {
  final List<IPTVPlaylistSource> sources;
  final String? selectedId;
  final ValueChanged<IPTVPlaylistSource> onSelect;

  const _PlaylistPickerSheet({
    required this.sources,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Playlists',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final selected = source.id == selectedId;
                  return ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.playlist_play_rounded,
                  size: 18,
                  color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.5),
                ),
              ),
              title: Text(
                source.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.85),
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelect(source);
              },
            );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Bar Button ────────────────────────────────────────────────────────

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 14),
            Text(
              query.isEmpty ? 'No channels found' : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading Indicator ────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

// ─── Coming Soon ──────────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.construction_rounded,
            size: 40, color: Colors.white.withOpacity(0.18)),
        const SizedBox(height: 12),
        Text(
          'Coming soon',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}

// ─── Internal models ──────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}