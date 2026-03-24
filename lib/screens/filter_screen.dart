import 'package:flutter/material.dart';
import '../models/streamengine/stream_models.dart';
import '../services/streamengine_service.dart';
import '../utils/tmdb_config.dart';
import '../theme/app_theme.dart';
import 'content_detail_screen.dart';

class FilterScreen extends StatefulWidget {
  final String initialType; // 'movie' or 'tv'
  final String? initialGenreId;
  final String initialLanguage;
  final String? initialYear;

  const FilterScreen({
    super.key,
    this.initialType = 'movie',
    this.initialGenreId,
    this.initialLanguage = 'en',
    this.initialYear,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final StreamEngineService _service = StreamEngineService();
  final ScrollController _scrollController = ScrollController();
  
  late String _currentType;
  String? _currentGenreId;
  late String _currentLang;
  String? _currentYear;

  List<StreamItem> _items = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _currentGenreId = widget.initialGenreId;
    _currentLang = widget.initialLanguage;
    _currentYear = widget.initialYear;

    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadData();
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _items.clear();
        _currentPage = 1;
        _hasMore = true;
      });
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final params = <String, String>{};
      if (_currentGenreId != null) params['with_genres'] = _currentGenreId!;
      if (_currentLang != 'All') params['with_original_language'] = _currentLang;
      if (_currentYear != null) {
        if (_currentType == 'movie') {
          params['primary_release_year'] = _currentYear!;
        } else {
          params['first_air_date_year'] = _currentYear!;
        }
      }

      final results = await _service.discover(
        type: _currentType,
        params: params,
        page: _currentPage,
        language: 'en', // UI language is english for now, but original_language filters content
      );

      if (mounted) {
        setState(() {
          if (results.isEmpty) {
            _hasMore = false;
          } else {
            _items.addAll(results);
            _currentPage++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSelectionDialog(String title, List<Map<String, dynamic>> options, String? currentValue, Function(String?) onSelect) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 300,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final opt = options[index];
                      final isSelected = opt['id']?.toString() == currentValue?.toString();
                      return ListTile(
                        autofocus: isSelected || index == 0,
                        title: Text(opt['name'], style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(opt['id']?.toString());
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return _FilterChip(label: label, value: value, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    // derive display labels
    final typeLabel = _currentType == 'movie' ? 'Movies' : 'Series';
    final genreLabel = TmdbConfig.homeGenres.firstWhere((g) => g['id']?.toString() == _currentGenreId, orElse: () => {'name': 'All'})['name'] as String;
    final langLabel = TmdbConfig.languages.firstWhere((l) => l['id'] == _currentLang, orElse: () => {'name': 'All'})['name'] as String;
    final yearLabel = _currentYear ?? 'All';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Filters Bar
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterChip('Type', typeLabel, () {
                    _openSelectionDialog('Select Type', [
                      {'id': 'movie', 'name': 'Movies'},
                      {'id': 'tv', 'name': 'Series'},
                    ], _currentType, (v) {
                      if (v != null && v != _currentType) {
                        setState(() { _currentType = v; _loadData(refresh: true); });
                      }
                    });
                  }),
                  _buildFilterChip('Genre', genreLabel, () {
                    _openSelectionDialog('Select Genre', TmdbConfig.homeGenres, _currentGenreId, (v) {
                      if (v != _currentGenreId) {
                        setState(() { _currentGenreId = v; _loadData(refresh: true); });
                      }
                    });
                  }),
                  _buildFilterChip('Language', langLabel, () {
                    final langs = [{'id': 'All', 'name': 'All'}, ...TmdbConfig.languages];
                    _openSelectionDialog('Select Language', langs, _currentLang, (v) {
                      if (v != null && v != _currentLang) {
                        setState(() { _currentLang = v; _loadData(refresh: true); });
                      }
                    });
                  }),
                  _buildFilterChip('Year', yearLabel, () {
                    final years = [{'id': null, 'name': 'All'}];
                    final currentYearInt = DateTime.now().year;
                    for (int i = currentYearInt; i >= 1950; i--) {
                      years.add({'id': i.toString(), 'name': i.toString()});
                    }
                    _openSelectionDialog('Select Year', years, _currentYear, (v) {
                      if (v != _currentYear) {
                        setState(() { _currentYear = v; _loadData(refresh: true); });
                      }
                    });
                  }),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: _items.isEmpty && !_isLoading
                  ? const Center(child: Text('No results found.', style: TextStyle(color: Colors.white)))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final item = _items[index];
                        return _GridItem(item: item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Text(
                '${widget.label}: ',
                style: TextStyle(color: _isFocused ? Colors.white : Colors.white70, fontSize: 13),
              ),
              Text(
                widget.value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridItem extends StatefulWidget {
  final StreamItem item;

  const _GridItem({required this.item});

  @override
  State<_GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<_GridItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentDetailScreen(
                contentId: widget.item.id,
                isMovie: widget.item is StreamMovie,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: 3),
              boxShadow: _isFocused ? [BoxShadow(color: Colors.black54, blurRadius: 10)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: widget.item.poster != null
                  ? Image.network(
                      widget.item.poster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                    )
                  : Container(
                      color: Colors.grey[900],
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Text(widget.item.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
