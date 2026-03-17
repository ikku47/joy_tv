import 'package:flutter/material.dart';
import '../models/iptv_channel.dart';
import '../services/playlist_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/channel_grid.dart';
import '../widgets/home/bottom_bar_button.dart';
import '../widgets/home/playlist_picker_sheet.dart';
import '../widgets/common/status_widgets.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kMobileBreak  = 600.0;

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
    HomeNavItem(icon: Icons.live_tv_rounded,   label: 'Live'),
    HomeNavItem(icon: Icons.movie_rounded,     label: 'Movies'),
    HomeNavItem(icon: Icons.tv_rounded,        label: 'Series'),
    HomeNavItem(icon: Icons.star_rounded,      label: 'Favorites'),
    HomeNavItem(icon: Icons.settings_rounded,  label: 'Settings'),
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
              if (!isMobile) HomeSidebar(
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
                child: BottomBarButton(
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
        HomeHeader(
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
            child: HomeSearchBar(
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
                ? const Center(child: LoadingIndicator())
                : _filteredChannels.isEmpty
                    ? EmptyState(query: _searchQuery)
                    : ChannelGrid(
                        channels: _filteredChannels,
                        isMobile: isMobile,
                        scrollController: _scrollController,
                        hPad: hPad,
                      ),
          ),
        ] else
          const Expanded(child: Center(child: ComingSoon())),
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
      builder: (ctx) => PlaylistPickerSheet(
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