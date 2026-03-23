import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/streamengine/stream_models.dart';
import '../services/streamengine_service.dart';
import '../widgets/common/status_widgets.dart';
import '../screens/stream_player_screen.dart';
import '../utils/extensions.dart';

class ContentDetailScreen extends StatefulWidget {
  final String contentId;
  final bool isMovie;

  const ContentDetailScreen({super.key, required this.contentId, required this.isMovie});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final StreamEngineService _service = StreamEngineService();
  StreamMovie? _movie;
  StreamTvShow? _tvShow;
  bool _isLoading = true;
  String? _error;
  List<StreamEpisode>? _episodes;
  StreamSeason? _selectedSeason;
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _error = null;
      });
    try {
      if (widget.isMovie) {
        _movie = await _service.getMovieDetails(widget.contentId);
      } else {
        _tvShow = await _service.getTvShowDetails(widget.contentId);
        if (_tvShow != null && _tvShow!.seasons != null && _tvShow!.seasons!.isNotEmpty) {
          _selectedSeason = _tvShow!.seasons!.first;
          _episodes = await _service.getEpisodes(_selectedSeason!.id);
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
    }
  }

  Future<void> _selectSeason(StreamSeason season) async {
    if (_selectedSeason?.id == season.id) return;
    setState(() {
      _selectedSeason = season;
      _episodes = null;
      _loadingEpisodes = true;
    });
    final eps = await _service.getEpisodes(season.id);
    if (mounted)
      setState(() {
        _episodes = eps;
        _loadingEpisodes = false;
      });
  }

  void _playMovie() {
    if (_movie == null) return;
    Navigator.push(
      context,
      _pageRoute(StreamPlayerScreen(contentId: _movie!.id, tvShowId: _movie!.id, type: 'movie', title: _movie!.title)),
    );
  }

  void _playEpisode(StreamEpisode ep) {
    if (_tvShow == null || _selectedSeason == null) return;
    Navigator.push(
      context,
      _pageRoute(
        StreamPlayerScreen(
          contentId: ep.id,
          tvShowId: _tvShow!.id,
          type: 'episode',
          seasonNumber: _selectedSeason!.number,
          episodeNumber: ep.number,
          title: '${_tvShow!.title} — S${_selectedSeason!.number}E${ep.number}: ${ep.title}',
          allEpisodes: _episodes,
          initialEpisodeIndex: _episodes?.indexOf(ep) ?? 0,
          allSeasons: _tvShow!.seasons,
          tvShowTitle: _tvShow!.title,
        ),
      ),
    );
  }

  PageRoute _pageRoute(Widget screen) => PageRouteBuilder(
    pageBuilder: (_, _, _) => screen,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: LoadingIndicator()),
      );
    }
    if (_error != null || (_movie == null && _tvShow == null)) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 12),
              Text(_error ?? 'Content not found', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final banner = _movie?.banner ?? _tvShow?.banner;
    final poster = _movie?.poster ?? _tvShow?.poster;
    final title = _movie?.title ?? _tvShow?.title ?? '';
    final overview = _movie?.overview ?? _tvShow?.overview;
    final rating = _movie?.rating ?? _tvShow?.rating;
    final released = _movie?.released ?? _tvShow?.released;
    final cast = _movie?.cast ?? _tvShow?.cast;
    final recs = _movie?.recommendations ?? _tvShow?.recommendations;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          // Blurred background image
          if (banner != null || poster != null)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(banner ?? poster!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: const Color(0xFF0D0D1A).withOpacity(0.82)),
                  ),
                ],
              ),
            ),

          CustomScrollView(
            slivers: [
              // Hero banner area
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Banner image with gradient overlay
                    SizedBox(
                      height: 340,
                      width: double.infinity,
                      child: banner != null
                          ? Image.network(banner, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox())
                          : const SizedBox(),
                    ),
                    Container(
                      height: 340,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x440D0D1A), Color(0xFF0D0D1A)],
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster + meta row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (poster != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                poster,
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    if (released.releaseYear != null)
                                      _MetaBadge(icon: Icons.calendar_today_outlined, label: released.releaseYear!),
                                    if (rating != null)
                                      _MetaBadge(
                                        icon: Icons.star_rounded,
                                        label: rating.toStringAsFixed(1),
                                        iconColor: Colors.amber,
                                      ),
                                    if (_movie?.runtime != null)
                                      _MetaBadge(icon: Icons.timer_outlined, label: '${_movie!.runtime} min'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (widget.isMovie) _WatchNowButton(onTap: _playMovie),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Overview
                      if (overview != null && overview.isNotEmpty) ...[
                        const _SectionHeader('Synopsis'),
                        const SizedBox(height: 8),
                        Text(
                          overview,
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Series: Season + Episodes
                      if (!widget.isMovie && _tvShow?.seasons != null) ...[
                        const _SectionHeader('Episodes'),
                        const SizedBox(height: 12),
                        _SeasonBar(
                          seasons: _tvShow!.seasons!,
                          selectedSeason: _selectedSeason,
                          onSelected: _selectSeason,
                        ),
                        const SizedBox(height: 16),
                        if (_loadingEpisodes)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: LoadingIndicator()),
                          )
                        else if (_episodes != null && _episodes!.isNotEmpty)
                          _EpisodeListWidget(episodes: _episodes!, onTap: _playEpisode)
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No episodes found', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        const SizedBox(height: 28),
                      ],

                      // Cast
                      if (cast != null && cast.isNotEmpty) ...[
                        const _SectionHeader('Cast'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 115,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: cast.length,
                            itemBuilder: (_, i) => _CastCard(person: cast[i]),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Similar / Recommendations
                      if (recs != null && recs.isNotEmpty) ...[
                        const _SectionHeader('More Like This'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recs.length,
                            itemBuilder: (_, i) => _RecCard(item: recs[i]),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
  );
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _MetaBadge({required this.icon, required this.label, this.iconColor = Colors.grey});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: iconColor, size: 14),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  );
}

class _WatchNowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WatchNowButton({required this.onTap});

  @override
  State<_WatchNowButton> createState() => _WatchNowButtonState();
}

class _WatchNowButtonState extends State<_WatchNowButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _focused ? Colors.white : Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _focused
                ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: _focused ? Colors.black : Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'WATCH NOW',
                style: TextStyle(
                  color: _focused ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonBar extends StatelessWidget {
  final List<StreamSeason> seasons;
  final StreamSeason? selectedSeason;
  final Function(StreamSeason) onSelected;

  const _SeasonBar({required this.seasons, this.selectedSeason, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        itemBuilder: (_, i) {
          final s = seasons[i];
          final isSelected = s.id == selectedSeason?.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white24, width: 1),
                ),
                child: Text(
                  s.title ?? 'Season ${s.number}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpisodeListWidget extends StatelessWidget {
  final List<StreamEpisode> episodes;
  final Function(StreamEpisode) onTap;

  const _EpisodeListWidget({required this.episodes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: episodes.map((ep) => _EpisodeTile(episode: ep, onTap: () => onTap(ep))).toList(),
    );
  }
}

class _EpisodeTile extends StatefulWidget {
  final StreamEpisode episode;
  final VoidCallback onTap;
  const _EpisodeTile({required this.episode, required this.onTap});

  @override
  State<_EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<_EpisodeTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
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
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _focused ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _focused ? Colors.blueAccent : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 100,
                  height: 58,
                  color: const Color(0xFF1A1A2E),
                  child: widget.episode.poster != null
                      ? Image.network(
                          widget.episode.poster!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.play_circle_outline, color: Colors.grey),
                        )
                      : const Center(child: Icon(Icons.play_circle_outline, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E${widget.episode.number}: ${widget.episode.title}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.episode.released != null && widget.episode.released!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.episode.released.asFullDate(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.play_circle_filled_rounded, color: _focused ? Colors.blueAccent : Colors.white38, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  final StreamPeople person;
  const _CastCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: person.image != null ? NetworkImage(person.image!) : null,
            backgroundColor: const Color(0xFF1A1A2E),
            child: person.image == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(height: 6),
          Text(
            person.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RecCard extends StatefulWidget {
  final StreamItem item;
  const _RecCard({required this.item});

  @override
  State<_RecCard> createState() => _RecCardState();
}

class _RecCardState extends State<_RecCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContentDetailScreen(contentId: widget.item.id, isMovie: widget.item is StreamMovie),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _focused ? Colors.blueAccent : Colors.transparent, width: 2),
            boxShadow: _focused ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.item.poster != null
                ? Image.network(
                    widget.item.poster!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A2E)),
                  )
                : Container(
                    color: const Color(0xFF1A1A2E),
                    child: Center(
                      child: Text(
                        widget.item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
