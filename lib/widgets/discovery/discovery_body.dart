import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/streamengine_service.dart';
import '../../models/streamengine/stream_models.dart';
import '../../utils/extensions.dart';
import '../../widgets/common/status_widgets.dart';
import '../../screens/content_detail_screen.dart';
import '../../theme/app_theme.dart';
import 'dart:ui';
import 'dart:async';

class DiscoveryBody extends StatefulWidget {
  final bool isMobile;
  final double hPad;
  final String section; // "movies" or "series"

  const DiscoveryBody({super.key, required this.isMobile, required this.hPad, required this.section});

  @override
  State<DiscoveryBody> createState() => _DiscoveryBodyState();
}

class _DiscoveryBodyState extends State<DiscoveryBody> {
  final StreamEngineService _service = StreamEngineService();
  List<StreamCategory>? _categories;
  bool _isLoading = true;
  bool _hasError = false;
  late PageController _heroController;
  int _heroIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
    _loadData();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_categories != null && _categories!.isNotEmpty) {
        final heroCount = _categories![0].items.take(6).length;
        if (heroCount > 1) {
          final next = (_heroIndex + 1) % heroCount;
          _heroController.animateToPage(
            next,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoveryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await _service.getHome(section: widget.section);
      if (!mounted) return;
      setState(() {
        // Ensure we have enough categories by adding mock ones if needed ? 
        // No, let's trust the real engine or just show what's there.
        _categories = data.where((c) => c.items.isNotEmpty).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
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

    final heroItems = _categories![0].items.take(6).toList();

    return CustomScrollView(
      slivers: [
        // ── Hero Section ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _DiscoveryHero(
            items: heroItems,
            controller: _heroController,
            isMobile: widget.isMobile,
            currentIndex: _heroIndex,
            onPageChanged: (i) => setState(() => _heroIndex = i),
          ),
        ),

        // ── Categories List ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = _categories![index];
                return _DiscoveryRow(
                  category: category,
                  hPad: widget.hPad,
                  isMobile: widget.isMobile,
                );
              },
              childCount: _categories!.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero Widget ──────────────────────────────────────────────────────────────

class _DiscoveryHero extends StatelessWidget {
  final List<StreamItem> items;
  final PageController controller;
  final bool isMobile;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _DiscoveryHero({
    required this.items,
    required this.controller,
    required this.isMobile,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final height = isMobile ? 420.0 : 620.0;
    
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _HeroSlide(item: item, isMobile: isMobile);
            },
          ),
          
          // Slider Dots
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: active ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primaryColor : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final StreamItem item;
  final bool isMobile;

  const _HeroSlide({required this.item, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final banner = item.banner ?? item.poster;
    final hPad = isMobile ? 24.0 : 60.0;
    final topOffset = isMobile ? 120.0 : 140.0;

    return GestureDetector(
      onTap: () => _navigateToDetail(context, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (banner != null)
            Image.network(
              banner,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(color: Colors.black),
          
          // Multi-layer Gradients for cinematic look
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0, 0.5, 0.8],
                colors: [
                  Colors.black,
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, topOffset, hPad, 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TRENDING NOW',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
                ),

                // Title Logo / Text
                Text(
                  item.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: isMobile ? -0.5 : -1,
                    height: 1,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Info badges / Meta
                Row(
                  children: [
                    if (item.rating != null) ...[
                      const Icon(Icons.star_rounded, color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        item.rating!.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ' / 10',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      const SizedBox(width: 20),
                    ],
                    Text(
                      item.released.releaseYear ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Description
                if (item is StreamMovie && (item as StreamMovie).overview != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: SizedBox(
                      width: isMobile ? double.infinity : 650,
                      child: Text(
                        (item as StreamMovie).overview!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                
                // Action Buttons
                Row(
                  children: [
                    _HeroButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Watch Now',
                      primary: true,
                      onPressed: () => _navigateToDetail(context, item),
                    ),
                    const SizedBox(width: 16),
                    _HeroButton(
                      icon: Icons.add_rounded,
                      label: 'Watchlist',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    _HeroButton(
                      icon: Icons.info_outline_rounded,
                      label: '',
                      onPressed: () => _navigateToDetail(context, item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, StreamItem item) {
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
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onPressed;

  const _HeroButton({
    required this.icon,
    required this.label,
    this.primary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 16 : 28,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: primary ? Colors.white : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            boxShadow: primary ? [
              BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primary ? Colors.black : Colors.white, size: 26),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: primary ? Colors.black.withOpacity(0.9) : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Discovery Row (Landscape Cards) ──────────────────────────────────────────

class _DiscoveryRow extends StatelessWidget {
  final StreamCategory category;
  final double hPad;
  final bool isMobile;

  const _DiscoveryRow({
    required this.category,
    required this.hPad,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final height = isMobile ? 130.0 : 190.0;
    final width = isMobile ? 200.0 : 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, isMobile ? 25 : 35, hPad, isMobile ? 12 : 18),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isMobile ? 12 : 16,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
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
              );
            },
          ),
        ),
      ],
    );
  }
}


class _LandscapeCard extends StatefulWidget {
  final StreamItem item;
  final double width;
  final double height;

  const _LandscapeCard({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  State<_LandscapeCard> createState() => _LandscapeCardState();
}

class _LandscapeCardState extends State<_LandscapeCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.item.banner ?? widget.item.poster;

    return Focus(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentDetailScreen(
                contentId: widget.item.id,
                isMovie: widget.item is StreamMovie,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Hero(
            tag: 'poster-${widget.item.id}',
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isFocused ? [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
                ] : [],
                border: Border.all(
                  color: _isFocused ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.08),
                  width: _isFocused ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (banner != null)
                      Image.network(
                        banner,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                      )
                    else
                      Container(color: Colors.grey[900]),
                    
                    // Bottom gradient for title
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
