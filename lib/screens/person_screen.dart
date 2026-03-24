import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/streamengine/stream_models.dart';
import '../../services/streamengine_service.dart';
import '../../widgets/common/status_widgets.dart';
import 'content_detail_screen.dart';

class PersonScreen extends StatefulWidget {
  final String personId;
  final String initialName;

  const PersonScreen({
    super.key,
    required this.personId,
    required this.initialName,
  });

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  final StreamEngineService _service = StreamEngineService();
  StreamPeople? _person;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPerson();
  }

  Future<void> _fetchPerson() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getPeople(widget.personId);
      if (mounted) {
        setState(() {
          _person = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.initialName),
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }

    if (_error != null || _person == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.initialName),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text('Unable to load details for ${widget.initialName}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchPerson,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filmography = _person!.filmography ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D0D1A),
            pinned: true,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: _person!.image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(_person!.image!, fit: BoxFit.cover, alignment: Alignment.topCenter),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF0D0D1A).withOpacity(0.3),
                                  const Color(0xFF0D0D1A),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_person!.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _person!.image!,
                        width: 140,
                        height: 210,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _person!.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_person!.birthday != null)
                          _InfoRow(icon: Icons.cake, text: 'Born: ${_person!.birthday}'),
                        if (_person!.placeOfBirth != null)
                          _InfoRow(icon: Icons.location_on, text: _person!.placeOfBirth!),
                        if (_person!.deathday != null)
                          _InfoRow(icon: Icons.close, text: 'Died: ${_person!.deathday}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_person!.biography != null && _person!.biography!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Biography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(
                      _person!.biography!,
                      style: TextStyle(fontSize: 14, height: 1.6, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
          if (filmography.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: const Text('Filmography', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filmography[index];
                    return _FilmographyCard(item: item);
                  },
                  childCount: filmography.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmographyCard extends StatefulWidget {
  final StreamItem item;
  const _FilmographyCard({required this.item});

  @override
  State<_FilmographyCard> createState() => _FilmographyCardState();
}

class _FilmographyCardState extends State<_FilmographyCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
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
          scale: _focused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10)]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
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
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
