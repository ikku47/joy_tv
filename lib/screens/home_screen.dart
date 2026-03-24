import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android_tv_text_field/native_textfield_tv.dart';

import '../models/iptv_channel.dart';
import '../services/m3u_parser.dart';
import '../theme/app_theme.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/channel_grid.dart';
import '../widgets/home/bottom_bar_button.dart';
import '../widgets/common/status_widgets.dart';
import '../widgets/home/category_list.dart';
import '../widgets/home/tv_live_layout.dart';
import '../widgets/discovery/discovery_body.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kMobileBreak    = 600.0;
const _kPlaylistUrl    =
    'https://raw.githubusercontent.com/ikku47/joy_tv/main/assets/default_playlist.m3u8';

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Mobile search (NativeTextField)
  final NativeTextFieldController _searchController =
      NativeTextFieldController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<IPTVChannel> _channels         = [];
  List<IPTVChannel> _filteredChannels = [];
  List<String> _categories            = [];

  bool _isLoading        = true;
  bool _isSearchFocused  = false;
  String _selectedCategory = 'All';
  int _selectedNavIndex    = 0;
  String _searchQuery      = '';

  // TV search state (passed into TvLiveLayout)
  String _tvSearchQuery = '';

  Timer? _searchDebounce;

  // Nav items shared across sidebar / bottom bar
  static const _navItems = [
    HomeNavItem(icon: Icons.live_tv_rounded,  label: 'Live'),
    HomeNavItem(icon: Icons.movie_rounded,    label: 'Movies'),
    HomeNavItem(icon: Icons.tv_rounded,       label: 'Series'),
    HomeNavItem(icon: Icons.star_rounded,     label: 'Favorites'),
    HomeNavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    _searchFocusNode.addListener(_onSearchFocusChange);

    _searchController.addListener(() {
      final q = _searchController.text.toLowerCase().trim();
      if (_searchQuery != q) {
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) setState(() { _searchQuery = q; _filterChannels(); });
        });
      }
    });
  }

  void _onSearchFocusChange() {
    final focused = _searchFocusNode.hasFocus;
    if (focused != _isSearchFocused) setState(() => _isSearchFocused = focused);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadPlaylist() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_kPlaylistUrl));
      if (!mounted) return;
      if (response.statusCode == 200) {
        _applyChannels(M3UParser.parse(response.body));
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyChannels(List<IPTVChannel> channels) {
    final categoriesSet = <String>{};
    for (final ch in channels) {
      final g = ch.group?.trim();
      categoriesSet.add((g != null && g.isNotEmpty) ? g : 'Uncategorized');
    }
    final sorted = categoriesSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      _channels          = channels;
      _categories        = ['All', ...sorted];
      _selectedCategory  = 'All';
      _isLoading         = false;
    });
    _filterChannels();
  }

  void _filterChannels({String? searchOverride}) {
    final q = searchOverride ?? _searchQuery;
    Iterable<IPTVChannel> filtered = _channels;

    if (_selectedCategory != 'All') {
      filtered = filtered.where((ch) {
        final g = ch.group?.trim();
        return ((g != null && g.isNotEmpty) ? g : 'Uncategorized') ==
            _selectedCategory;
      });
    }

    if (q.isNotEmpty) {
      filtered = filtered.where((ch) =>
          ch.name.toLowerCase().contains(q) ||
          (ch.group?.toLowerCase().contains(q) ?? false));
    }

    _filteredChannels = filtered.toList();
  }

  // ── TV search (propagated into TvLiveLayout) ────────────────────────────────

  /// Called by TvLiveLayout when the user types in the TV search bar.
  void _onTvSearch(String query) {
    final q = query.toLowerCase().trim();
    if (_tvSearchQuery == q) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _tvSearchQuery   = q;
        _searchQuery     = q;   // reuse same filter logic
        _filterChannels(searchOverride: q);
      });
    });
  }

  void _onTvSearchClear() {
    setState(() {
      _tvSearchQuery = '';
      _searchQuery   = '';
      _filterChannels(searchOverride: '');
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
              if (!isMobile)
                HomeSidebar(
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
            children: List.generate(_navItems.length - 1, (i) {
              final item    = _navItems[i];
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

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(bool isMobile) {
    final hPad = isMobile ? 16.0 : 28.0;

    // TV Live tab: full-height 3-column layout with no extra header
    if (!isMobile && _selectedNavIndex == 0) {
      return _buildMainContent(isMobile, hPad);
    }

    // All other tabs: header overlay + content
    return Stack(
      children: [
        Positioned.fill(child: _buildMainContent(isMobile, hPad)),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectedNavIndex == 1 || _selectedNavIndex == 2
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    )
                  : null,
            ),
            child: HomeHeader(
              isMobile: isMobile,
              navIndex: _selectedNavIndex,
              sources: const [],
              selectedSourceId: null,
              onSourcePick: () {},
              hPad: hPad,
            ),
          ),
        ),
      ],
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildMainContent(bool isMobile, double hPad) {
    if (_selectedNavIndex == 0) {
      // ── Android TV: 3-column layout ──────────────────────────────────────
      if (!isMobile) {
        return TvLiveLayout(
          categories: _categories,
          channels: _filteredChannels,
          allChannels: _channels,
          selectedCategory: _selectedCategory,
          isLoading: _isLoading,
          searchQuery: _tvSearchQuery,
          onCategorySelected: (cat) {
            setState(() { _selectedCategory = cat; _filterChannels(); });
          },
          onSearch: _onTvSearch,
          onSearchClear: _onTvSearchClear,
        );
      }

      // ── Mobile: search + category chips + grid ───────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 110),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
            child: HomeSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isFocused: _isSearchFocused,
              query: _searchQuery,
              onChanged: (v) {},
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterChannels();
                });
              },
            ),
          ),
          if (!_isLoading && _categories.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryList(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) {
                  setState(() { _selectedCategory = cat; _filterChannels(); });
                },
              ),
            ),
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
              child: Text(
                '${_filteredChannels.length} channels'
                    '${_selectedCategory != 'All' ? ' in $_selectedCategory' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ),
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
        ],
      );
    }

    if (_selectedNavIndex == 1) {
      return DiscoveryBody(
        key: const ValueKey('discovery-movies'),
        isMobile: isMobile,
        hPad: hPad,
        section: 'movies',
      );
    }

    if (_selectedNavIndex == 2) {
      return DiscoveryBody(
        key: const ValueKey('discovery-series'),
        isMobile: isMobile,
        hPad: hPad,
        section: 'series',
      );
    }

    if (_selectedNavIndex == 4) {
      return Column(
        children: [
          SizedBox(height: isMobile ? 110 : 100),
          Expanded(child: _buildSettings(hPad)),
        ],
      );
    }

    return const Center(child: ComingSoon());
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Widget _buildSettings(double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingsSection(
            title: 'Playlist Source',
            description: 'Channels are loaded from the official Joy TV playlist hosted on GitHub.',
            icon: Icons.cloud_done_rounded,
            action: Text(
              'Auto-managed',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'App Version',
            description: 'Current version: 1.3.0',
            icon: Icons.info_outline_rounded,
            action: Text(
              'Stable',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required String description,
    required IconData icon,
    required Widget action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          action,
        ],
      ),
    );
  }
}
