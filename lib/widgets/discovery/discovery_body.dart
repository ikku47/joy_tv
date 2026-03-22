import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/streamengine_service.dart';
import '../../models/streamengine/stream_models.dart';
import '../../utils/extensions.dart';
import '../../widgets/common/status_widgets.dart';
import '../../screens/content_detail_screen.dart';

class DiscoveryBody extends StatefulWidget {
  final bool isMobile;
  final double hPad;
  final String section; // "movies" or "series"

  const DiscoveryBody({
    super.key,
    required this.isMobile,
    required this.hPad,
    required this.section,
  });

  @override
  State<DiscoveryBody> createState() => _DiscoveryBodyState();
}

class _DiscoveryBodyState extends State<DiscoveryBody> {
  final StreamEngineService _service = StreamEngineService();
  List<StreamCategory>? _categories;
  bool _isLoading = true;
  bool _hasError = false;

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
      final data = await _service.getHome(section: widget.section);
      if (!mounted) return;
      setState(() {
        _categories = data.where((c) => c.items.isNotEmpty).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; });
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      );
    }

    final cardH = widget.isMobile ? 190.0 : 240.0;
    final cardW = widget.isMobile ? 120.0 : 155.0;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 40),
      itemCount: _categories!.length,
      itemBuilder: (context, index) {
        final category = _categories![index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(widget.hPad, 20, widget.hPad, 10),
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: widget.isMobile ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(
              height: cardH,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: widget.hPad),
                itemCount: category.items.length,
                itemBuilder: (context, i) => _StreamCard(
                  item: category.items[i],
                  cardHeight: cardH,
                  cardWidth: cardW,
                  isMobile: widget.isMobile,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StreamCard extends StatefulWidget {
  final StreamItem item;
  final double cardHeight;
  final double cardWidth;
  final bool isMobile;

  const _StreamCard({
    required this.item,
    required this.cardHeight,
    required this.cardWidth,
    required this.isMobile,
  });

  @override
  State<_StreamCard> createState() => _StreamCardState();
}

class _StreamCardState extends State<_StreamCard> with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleFocus(bool focused) {
    setState(() => _isFocused = focused);
    if (focused) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _navigate() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => ContentDetailScreen(
          contentId: widget.item.id,
          isMovie: widget.item is StreamMovie,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.item.released.releaseYear;

    return Focus(
      onFocusChange: _handleFocus,
      onKeyEvent: (node, event) {
        if ((event is KeyDownEvent) &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter)) {
          _navigate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _navigate,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: widget.cardWidth,
            margin: EdgeInsets.only(right: widget.isMobile ? 10 : 14),
            child: Stack(
              children: [
                // Card image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: widget.cardWidth,
                    height: widget.isMobile ? 160.0 : 200.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      boxShadow: _isFocused ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                    child: widget.item.poster != null
                        ? Image.network(
                            widget.item.poster!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie, color: Colors.grey)),
                          )
                        : const Center(child: Icon(Icons.movie, color: Colors.grey, size: 40)),
                  ),
                ),
                // Focus border
                if (_isFocused)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent, width: 3),
                        ),
                      ),
                    ),
                  ),
                // Bottom gradient + title
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        if (year != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            year,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Rating badge
                if (widget.item.rating != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            widget.item.rating!.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
    );
  }
}
