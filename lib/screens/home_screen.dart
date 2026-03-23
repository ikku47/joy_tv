import 'dart:async';
import 'package:flutter/material.dart';

import '../models/iptv_channel.dart';
import '../services/playlist_cache_service.dart';
import '../services/playlist_merge_service.dart';
import 'playlist_sync_screen.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';

import '../theme/app_theme.dart';
import '../widgets/home/home_sidebar.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/channel_grid.dart';
import '../widgets/home/bottom_bar_button.dart';
import '../widgets/home/playlist_picker_sheet.dart';
import '../widgets/common/status_widgets.dart';
import '../widgets/home/category_list.dart';
import '../widgets/discovery/discovery_body.dart';

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
  final PlaylistMergeService _mergeService = PlaylistMergeService();
  final NativeTextFieldController _searchController = NativeTextFieldController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<IPTVPlaylistSource> _sources = [];
  List<IPTVChannel> _channels = [];
  List<IPTVChannel> _filteredChannels = [];
  List<String> _categories = [];

  bool _isLoading = true;
  bool _isSearchFocused = false;
  String _selectedCategory = 'All';
  String? _selectedSourceId;
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  Timer? _searchDebounce;

  static final _unifiedSource = IPTVPlaylistSource(
    id: 'unified',
    name: 'My Unified Playlist (Verified)',
    url: '', 
  );

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
    
    // Using a listener on the controller is more reliable for Android TV native text fields
    _searchController.addListener(() {
      final String currentQuery = _searchController.text.toLowerCase().trim();
      if (_searchQuery != currentQuery) {
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _searchQuery = currentQuery;
              _filterChannels();
            });
          }
        });
      }
    });
  }

  void _onSearchFocusChange() {
    final focused = _searchFocusNode.hasFocus;
    if (focused != _isSearchFocused) {
      setState(() => _isSearchFocused = focused);
    }
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


  // ── Data ───────────────────────────────────────────────────────────────────

  void _filterChannels() {
    // Filter from the full source list
    Iterable<IPTVChannel> filtered = _channels;

    // 1. Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((ch) {
        final group = ch.group?.trim();
        final effectiveGroup = (group != null && group.isNotEmpty) ? group : 'Uncategorized';
        return effectiveGroup == _selectedCategory;
      });
    }

    // 2. Search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ch) {
        // Search in name and group
        final nameMatch = ch.name.toLowerCase().contains(_searchQuery);
        final groupMatch = ch.group?.toLowerCase().contains(_searchQuery) ?? false;
        return nameMatch || groupMatch;
      });
    }

    _filteredChannels = filtered.toList();
  }


  Future<void> _loadInitialData() async {
    final sources = await _cacheService.getSources();
    final hasUnified = await _mergeService.hasLocalPlaylist();
    
    if (!mounted) return;
    setState(() {
      _sources = hasUnified ? [_unifiedSource, ...sources] : sources;
      if (_sources.isNotEmpty) _selectedSourceId = _sources.first.id;
    });
    
    if (_sources.isNotEmpty) {
      if (hasUnified) {
        await _loadChannels(_unifiedSource);
      } else {
        await _loadChannels(_sources.first);
      }
    }
  }

  Future<void> _loadChannels(IPTVPlaylistSource source) async {
    setState(() => _isLoading = true);
    
    List<IPTVChannel> channels;
    if (source.id == 'unified') {
      channels = await _mergeService.getLocalPlaylist();
    } else {
      channels = await _cacheService.fetchPlaylist(source);
    }
    
    if (!mounted) return;
    setState(() {
      _channels = channels;

      final Set<String> categoriesSet = {};
      for (final ch in channels) {
        final group = ch.group?.trim();
        if (group != null && group.isNotEmpty) {
          categoriesSet.add(group);
        } else {
          categoriesSet.add('Uncategorized');
        }
      }
      final sortedCategories = categoriesSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _categories = ['All', ...sortedCategories];
      _selectedCategory = 'All';

      _filterChannels();
      _isLoading = false;
    });
  }

  void _triggerManualSync() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlaylistSyncScreen(manualTrigger: true),
      ),
    );
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

    return Stack(
      children: [
        // Content Area
        Positioned.fill(
          child: _buildMainContent(isMobile, hPad),
        ),

        // Header (Overlay)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: _selectedNavIndex == 1 || _selectedNavIndex == 2
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    )
                  : null,
            ),
            child: HomeHeader(
              isMobile: isMobile,
              navIndex: _selectedNavIndex,
              sources: _sources,
              selectedSourceId: _selectedSourceId,
              onSourcePick: _showPlaylistPicker,
              hPad: hPad,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isMobile, double hPad) {
    if (_selectedNavIndex == 0) {
      // Live TV / Search / Grid logic...
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isMobile ? 110 : 100), // Header space
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
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _filterChannels();
                  });
                },
              ),
            ),
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
              child: Text(
                '${_filteredChannels.length} channels' +
                    (_selectedCategory != 'All' ? ' in $_selectedCategory' : ''),
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
    } else if (_selectedNavIndex == 1) {
      return DiscoveryBody(
        key: const ValueKey('discovery-movies'),
        isMobile: isMobile,
        hPad: hPad,
        section: "movies",
      );
    } else if (_selectedNavIndex == 2) {
      return DiscoveryBody(
        key: const ValueKey('discovery-series'),
        isMobile: isMobile,
        hPad: hPad,
        section: "series",
      );
    } else if (_selectedNavIndex == 4) {
      return Column(
        children: [
          SizedBox(height: isMobile ? 110 : 100),
          Expanded(child: _buildSettings(hPad)),
        ],
      );
    } else {
      return const Center(child: ComingSoon());
    }
  }

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
            title: 'Playlist Synchronization',
            description: 'Combine all sources into one verified playlist. This process removes non-working streams.',
            icon: Icons.sync_rounded,
            action: ElevatedButton(
              onPressed: _triggerManualSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Unified Playlist'),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'App Version',
            description: 'Current version: 1.2.0',
            icon: Icons.info_outline_rounded,
            action: Text(
              'Steady',
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
