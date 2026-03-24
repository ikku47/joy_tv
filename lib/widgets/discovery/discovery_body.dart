import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import '../../services/streamengine_service.dart';
import '../../models/streamengine/stream_models.dart';
import '../../utils/extensions.dart';
import '../../widgets/common/status_widgets.dart';
import '../../screens/content_detail_screen.dart';
import '../../screens/filter_screen.dart';
import '../../theme/app_theme.dart';

import '../../utils/tmdb_config.dart';

class DiscoveryBody extends StatefulWidget {
  final bool isMobile;
  final double hPad;
  final String section;

  const DiscoveryBody({super.key, required this.isMobile, required this.hPad, required this.section});

  @override
  State<DiscoveryBody> createState() => _DiscoveryBodyState();
}

class _DiscoveryBodyState extends State<DiscoveryBody> {
  final StreamEngineService _service = StreamEngineService();
  List<StreamCategory>? _categories;
  List<StreamItem>? _genres;
  StreamItem? _focusedItem;
  bool _isLoading = true;
  bool _hasError = false;

  final ScrollController _mainScrollController = ScrollController();

  String _currentLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DiscoveryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      final configSection = widget.section.contains('movie') ? 'movies' : (widget.section.contains('series') ? 'series' : 'home');
      final configs = TmdbConfig.rowConfig[configSection] ?? TmdbConfig.rowConfig['home']!;

      final futures = await Future.wait([
        for (var c in configs) _service.getTmdbList(c['endpoint'] as String, language: _currentLang),
      ]);
      
      final homeData = <StreamCategory>[];
      for (int i = 0; i < configs.length; i++) {
        homeData.add(StreamCategory(
          name: configs[i]['title'] as String,
          items: futures[i],
        ));
      }

      final genreData = TmdbConfig.homeGenres.map((g) {
        return StreamItem.fromJson({
          'id': g['id']?.toString() ?? '',
          'title': g['name'],
        });
      }).toList();

      if (!mounted) return;
      setState(() {
        _categories = homeData.where((c) => c.items.isNotEmpty).toList();
        _genres = genreData;
        
        if (_categories != null && _categories!.isNotEmpty && _categories![0].items.isNotEmpty) {
          _focusedItem = _categories![0].items.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _onItemFocused(StreamItem item) {
    if (_focusedItem?.id != item.id) {
      setState(() => _focusedItem = item);
    }
  }

  void _openDetail(StreamItem item) {
    // If it's a genre (identified by having no poster and just name), we would navigate to a Genre screen
    // But since the provider returns Genres mapped to StreamItem without full schema yet, let's just open detail 
    // Wait, genres have no poster and no released date. Let's just catch them by title.
    if (item.poster == null && item.banner == null && item.released == null) {
      // Need a Genre Screen. For now, do nothing on genre tap.
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(
          contentId: item.id,
          isMovie: item is StreamMovie,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: LoadingIndicator());
    if (_hasError || _categories == null || _categories!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            const Text("No content found", style: TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Dynamic Background
        _DynamicBackground(item: _focusedItem),

        // 2. Focused Item Info (Top Half)
        Positioned(
          top: 0,
          left: widget.hPad,
          right: widget.hPad,
          height: MediaQuery.of(context).size.height * 0.45,
          child: _FocusedItemInfo(item: _focusedItem),
        ),

        // 3. Scrolling Rows (Bottom Half)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.45,
          left: 0,
          right: 0,
          bottom: 0,
          child: ListView.builder(
            controller: _mainScrollController,
            padding: const EdgeInsets.only(bottom: 60),
            // +1 for genres, +1 for languages
            itemCount: _categories!.length + 2,
            itemBuilder: (context, index) {
              if (index == 1) {
                return _GenreRow(
                  title: 'Explore Genres',
                  genres: _genres!,
                  hPad: widget.hPad,
                  onFocused: _onItemFocused,
                );
              }

              if (index == _categories!.length + 1) {
                return Column(
                  children: [
                    _LanguageRow(
                      hPad: widget.hPad,
                      currentType: widget.section == 'series' ? 'tv' : 'movie',
                    ),
                    _YearRow(
                      hPad: widget.hPad,
                      currentType: widget.section == 'series' ? 'tv' : 'movie',
                    ),
                  ],
                );
              }

              final catIndex = index > 1 ? index - 1 : index;
              final category = _categories![catIndex];

              return _DiscoveryRow(
                category: category,
                hPad: widget.hPad,
                isMobile: widget.isMobile,
                onItemFocused: _onItemFocused,
                onItemTap: _openDetail,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Dynamic Background ──────────────────────────────────────────────────────

class _DynamicBackground extends StatelessWidget {
  final StreamItem? item;
  const _DynamicBackground({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item?.banner ?? item?.poster;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: imageUrl == null
        ? Container(key: const ValueKey('empty'), color: const Color(0xFF0D0D1A))
        : Stack(
            key: ValueKey(imageUrl),
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D0D1A)),
              ),
              // Fade overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xFF0D0D1A)],
                    stops: [0.2, 0.8],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Side fade for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0D0D1A).withOpacity(0.9), Colors.transparent],
                    stops: const [0.0, 0.6],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Focused Item Info (Top Section) ─────────────────────────────────────────

class _FocusedItemInfo extends StatelessWidget {
  final StreamItem? item;
  const _FocusedItemInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();

    // If it's a genre item (which behaves mildly oddly as it lacks dates), handle gracefully
    final isGenre = item!.poster == null && item!.banner == null && item!.released == null;

    final title = item!.title.toUpperCase();
    final overview = (item is StreamMovie) ? (item as StreamMovie).overview : (item is StreamTvShow ? (item as StreamTvShow).overview : null);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.only(bottom: 20, right: 100),
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              if (!isGenre) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (item!.rating != null && item!.rating! > 0) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        item!.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item!.released != null)
                      Text(
                        item!.released!.split('-').first,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item is StreamMovie ? 'MOVIE' : 'SERIES',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  ],
                ),
              ],
              if (overview != null && overview.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 600,
                  child: Text(
                    overview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Standard Discovery Row ──────────────────────────────────────────────────

class _DiscoveryRow extends StatelessWidget {
  final StreamCategory category;
  final double hPad;
  final bool isMobile;
  final Function(StreamItem) onItemFocused;
  final Function(StreamItem) onItemTap;

  const _DiscoveryRow({
    required this.category,
    required this.hPad,
    required this.isMobile,
    required this.onItemFocused,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = isMobile ? 140.0 : 210.0;
    final width = isMobile ? 100.0 : 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
          child: Text(
            category.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: category.items.length,
            itemBuilder: (context, index) {
              return _LandscapeCard(
                item: category.items[index],
                width: width,
                height: height,
                onFocused: () => onItemFocused(category.items[index]),
                onTap: () => onItemTap(category.items[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Card Item (Portrait Posters) ────────────────────────────────────────────

class _LandscapeCard extends StatefulWidget {
  final StreamItem item;
  final double width;
  final double height;
  final VoidCallback onFocused;
  final VoidCallback onTap;

  const _LandscapeCard({
    required this.item,
    required this.width,
    required this.height,
    required this.onFocused,
    required this.onTap,
  });

  @override
  State<_LandscapeCard> createState() => _LandscapeCardState();
}

class _LandscapeCardState extends State<_LandscapeCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final poster = widget.item.poster ?? widget.item.banner;

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onFocused();
      },
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isFocused ? widget.width + 15 : widget.width,
          height: _isFocused ? widget.height + 20 : widget.height,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 3)]
                : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)],
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.white.withOpacity(0.05),
              width: _isFocused ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: poster != null
                ? Image.network(
                    poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                  )
                : Container(
                    color: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Special Genre Row ───────────────────────────────────────────────────────

class _GenreRow extends StatelessWidget {
  final String title;
  final List<StreamItem> genres;
  final double hPad;
  final Function(StreamItem) onFocused;

  const _GenreRow({
    required this.title,
    required this.genres,
    required this.hPad,
    required this.onFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final genre = genres[index];
              return _GenreChip(genre: genre, onFocused: () => onFocused(genre));
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _GenreChip extends StatefulWidget {
  final StreamItem genre;
  final VoidCallback onFocused;
  
  const _GenreChip({required this.genre, required this.onFocused});

  @override
  State<_GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<_GenreChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onFocused();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterScreen(
                initialGenreId: widget.genre.id,
                initialLanguage: 'All', // Default to All for Genre selection
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isFocused ? Colors.transparent : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            widget.genre.title,
            style: TextStyle(
              color: _isFocused ? Colors.black : Colors.white,
              fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Special Language & Year Rows ─────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final double hPad;
  final String currentType;

  const _LanguageRow({required this.hPad, required this.currentType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
          child: const Text(
            'Explore Languages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: TmdbConfig.languages.length,
            itemBuilder: (context, index) {
              final langMap = TmdbConfig.languages[index];
              return _LanguageChip(
                langName: langMap['name'] as String,
                langId: langMap['id'] as String,
                currentType: currentType,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatefulWidget {
  final String langName;
  final String langId;
  final String currentType;

  const _LanguageChip({
    required this.langName,
    required this.langId,
    required this.currentType,
  });

  @override
  State<_LanguageChip> createState() => _LanguageChipState();
}

class _LanguageChipState extends State<_LanguageChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterScreen(
                initialType: widget.currentType,
                initialLanguage: widget.langId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Text(
            widget.langName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  final double hPad;
  final String currentType;

  const _YearRow({required this.hPad, required this.currentType});

  @override
  Widget build(BuildContext context) {
    final List<String> years = [];
    final currentYear = DateTime.now().year;
    for (int i = 0; i < 20; i++) {
      years.add((currentYear - i).toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
          child: const Text(
            'Explore by Year',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              return _YearChip(
                year: year,
                currentType: currentType,
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _YearChip extends StatefulWidget {
  final String year;
  final String currentType;

  const _YearChip({required this.year, required this.currentType});

  @override
  State<_YearChip> createState() => _YearChipState();
}

class _YearChipState extends State<_YearChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilterScreen(
                initialType: widget.currentType,
                initialYear: widget.year,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isFocused ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isFocused ? Colors.white : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Text(
            widget.year,
            style: TextStyle(
              color: Colors.white,
              fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
