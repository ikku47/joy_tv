import 'dart:convert';
import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/streamengine/stream_models.dart';
import '../services/streamengine_service.dart';
import '../widgets/common/status_widgets.dart';

class StreamPlayerScreen extends StatefulWidget {
  final String contentId;   // episodeId (for episode) or movieId (for movie)
  final String tvShowId;    // tmdb tvshow id (same as contentId for movies)
  final String type;        // "movie" or "episode"
  final String title;
  final int? seasonNumber;
  final int? episodeNumber;
  // Series only extras:
  final List<StreamEpisode>? allEpisodes;
  final int initialEpisodeIndex;
  final List<StreamSeason>? allSeasons;
  final String? tvShowTitle;

  const StreamPlayerScreen({
    super.key,
    required this.contentId,
    required this.tvShowId,
    required this.type,
    required this.title,
    this.seasonNumber,
    this.episodeNumber,
    this.allEpisodes,
    this.initialEpisodeIndex = 0,
    this.allSeasons,
    this.tvShowTitle,
  });

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen> {
  final StreamEngineService _service = StreamEngineService();
  BetterPlayerController? _playerController;

  List<VideoServer>? _servers;
  VideoServer? _currentServer;
  bool _isLoadingServers = true;
  bool _isLoadingVideo = false;
  String? _error;

  // Playback state
  double _speed = 1.0;
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  BoxFit _currentFit = BoxFit.contain;
  static const _fitModes = [
    MapEntry('Fit Screen', BoxFit.contain),
    MapEntry('Fill Screen', BoxFit.cover),
    MapEntry('Stretch', BoxFit.fill),
  ];

  BetterPlayerAsmsTrack? get _currentTrack => _playerController?.betterPlayerAsmsTrack;
  List<BetterPlayerAsmsTrack>? get _tracks => _playerController?.betterPlayerAsmsTracks;

  // Episode panel
  bool _showSettingsPanel = false;
  late int _currentEpisodeIndex;
  List<StreamEpisode>? _currentEpisodeList;
  StreamSeason? _currentSeason;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _currentEpisodeList = widget.allEpisodes;
    if (widget.allSeasons != null && widget.seasonNumber != null) {
      _currentSeason = widget.allSeasons!
          .firstWhere((s) => s.number == widget.seasonNumber, orElse: () => widget.allSeasons!.first);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _fetchServers();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _playerController?.dispose();
    super.dispose();
  }

  // ─── Server & Video loading ────────────────────────────────────

  Future<void> _fetchServers({
    int? overrideEpNumber,
    int? overrideSeasonNumber,
    String? overrideEpId,
  }) async {
    setState(() {
      _isLoadingServers = true;
      _error = null;
      _servers = null;
    });

    final isEpisode = widget.type == 'episode';
    final epNum = overrideEpNumber ?? widget.episodeNumber ?? 1;
    final snNum = overrideSeasonNumber ?? widget.seasonNumber ?? 1;
    final epId = overrideEpId ?? widget.contentId;

    try {
      final servers = await _service.getServers(
        isEpisode ? widget.tvShowId : widget.contentId,
        type: widget.type,
        tvShowId: isEpisode ? widget.tvShowId : null,
        seasonNumber: isEpisode ? snNum : null,
        episodeNumber: isEpisode ? epNum : null,
        episodeId: isEpisode ? epId : null,
      );

      if (!mounted) return;

      if (servers.isEmpty) {
        setState(() {
          _isLoadingServers = false;
          _error = 'No servers found for this content.\n\nThis may be region-restricted or not yet available.';
        });
        return;
      }

      setState(() {
        _servers = servers;
        _isLoadingServers = false;
      });
      _loadServer(servers.first);
    } catch (e) {
      if (mounted) setState(() { _isLoadingServers = false; _error = 'Server error: $e'; });
    }
  }

  // Resolve data: base64 URIs → temp file path so BetterPlayer can load it
  Future<String> _resolveVideoSource(String source) async {
    if (!source.startsWith('data:')) return source;
    // Parse:  data:<mime>;base64,<data>
    final commaIdx = source.indexOf(',');
    if (commaIdx < 0) return source;
    final base64Data = source.substring(commaIdx + 1);
    final bytes = base64Decode(base64Data);
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/stream_${DateTime.now().millisecondsSinceEpoch}.m3u8');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _loadServer(VideoServer server) async {
    if (mounted) setState(() { _currentServer = server; _isLoadingVideo = true; _error = null; });

    try {
      final video = await _service.extractVideo(server);
      if (video == null || video.source.isEmpty) throw 'Empty video source from ${server.name}';

      final rawSource = video.source;
      if (rawSource.isEmpty) throw 'Empty video source from ${server.name}';

      // Resolve base64 data URIs to a temp file
      final resolvedSource = await _resolveVideoSource(rawSource);

      final dataSource = BetterPlayerDataSource(
        resolvedSource.startsWith('/') || resolvedSource.startsWith('file://')
            ? BetterPlayerDataSourceType.file
            : BetterPlayerDataSourceType.network,
        resolvedSource,
        headers: resolvedSource.startsWith('/') ? null : video.headers,
        subtitles: [],
      );

      if (_playerController == null) {
        _playerController = BetterPlayerController(
          BetterPlayerConfiguration(
            autoPlay: true,
            looping: false,
            allowedScreenSleep: false,
            fullScreenByDefault: false,
            deviceOrientationsAfterFullScreen: [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
            controlsConfiguration: const BetterPlayerControlsConfiguration(
              enablePlaybackSpeed: false,
              enableSkips: true,
              enableFullscreen: false,
              forwardSkipTimeInMilliseconds: 10000,
              backwardSkipTimeInMilliseconds: 10000,
              controlBarColor: Colors.black54,
              iconsColor: Colors.white,
              progressBarPlayedColor: Colors.blueAccent,
              progressBarHandleColor: Colors.white,
              progressBarBackgroundColor: Colors.white24,
            ),
          ),
          betterPlayerDataSource: dataSource,
        );
      } else {
        await _playerController!.setupDataSource(dataSource);
        _playerController!.setSpeed(_speed);
      }

      if (mounted) setState(() => _isLoadingVideo = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _error = 'Extraction failed for "${server.name}":\n$e\n\nTry switching server.';
        });
      }
    }
  }

  // ─── Episode switching ─────────────────────────────────────────

  Future<void> _switchToEpisode(StreamEpisode ep, {StreamSeason? season}) async {
    final targetSeason = season ?? _currentSeason;
    if (!mounted) return;
    setState(() {
      _showSettingsPanel = false;
      _currentEpisodeIndex = _currentEpisodeList?.indexOf(ep) ?? 0;
      _currentSeason = targetSeason;
      _playerController?.dispose();
      _playerController = null;
    });
    await _fetchServers(
      overrideEpNumber: ep.number,
      overrideSeasonNumber: targetSeason?.number,
      overrideEpId: ep.id,
    );
  }

  Future<void> _loadSeasonEpisodes(StreamSeason season) async {
    final eps = await _service.getEpisodes(season.id);
    if (mounted) setState(() { _currentEpisodeList = eps; _currentSeason = season; });
  }

  // ─── Speed control ─────────────────────────────────────────────

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    final next = _speeds[(idx + 1) % _speeds.length];
    setState(() => _speed = next);
    _playerController?.setSpeed(next);
  }

  void _cycleFit() {
    setState(() {
      final currentIdx = _fitModes.indexWhere((e) => e.value == _currentFit);
      _currentFit = _fitModes[(currentIdx + 1) % _fitModes.length].value;
      _playerController?.setOverriddenFit(_currentFit);
    });
  }

  void _showTrackPicker(BuildContext context) {
    final trks = _tracks;
    if (trks == null || trks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Video Quality',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(color: Colors.white12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: trks.length,
                  itemBuilder: (_, i) {
                    final t = trks[i];
                    final isSelected = t.width == _currentTrack?.width && t.height == _currentTrack?.height && t.bitrate == _currentTrack?.bitrate;
                    final resName = t.height == 0 ? 'Auto' : '${t.height}p';
                    return ListTile(
                      onTap: () {
                        setState(() { _playerController?.setTrack(t); });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        isSelected ? Icons.high_quality_rounded : Icons.photo_size_select_actual_rounded,
                        color: isSelected ? Colors.blueAccent : Colors.white54,
                      ),
                      title: Text(resName,
                          style: TextStyle(
                            color: isSelected ? Colors.blueAccent : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ─── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Player ──
          if (_playerController != null)
            BetterPlayer(controller: _playerController!),

          // ── Loading overlay ──
          if (_isLoadingServers || _isLoadingVideo)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoadingIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _isLoadingServers ? 'Finding servers…' : 'Loading stream…',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_currentServer != null && _isLoadingVideo) ...[
                      const SizedBox(height: 6),
                      Text(
                        _currentServer!.name,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── Error overlay ──
          if (_error != null && !_isLoadingServers && !_isLoadingVideo)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                        const SizedBox(height: 16),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _fetchServers,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                            ),
                            if (_servers != null && _servers!.length > 1) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showServerPicker(context),
                                icon: const Icon(Icons.dns_rounded, size: 18),
                                label: const Text('Switch Server'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Top bar (title + back + settings) ──
          if (!_isLoadingServers && !_isLoadingVideo && _error == null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                title: widget.title,
                onBack: () => Navigator.pop(context),
                onSettings: () => setState(() => _showSettingsPanel = !_showSettingsPanel),
              ),
            ),

          // ── Settings side panel ──
          if (_showSettingsPanel)
            Positioned(
              top: 0, right: 0, bottom: 0,
              child: _SettingsPanel(
                type: widget.type,
                speed: _speed,
                currentServer: _currentServer,
                servers: _servers,
                episodes: widget.type == 'episode' ? (_currentEpisodeList ?? []) : null,
                seasons: widget.allSeasons,
                currentSeason: _currentSeason,
                currentIndex: _currentEpisodeIndex,
                currentFit: _currentFit,
                currentTrack: _currentTrack,
                hasTracks: (_tracks != null && _tracks!.length > 1),
                fitName: _fitModes.firstWhere((e) => e.value == _currentFit).key,
                onSpeedTap: _cycleSpeed,
                onServerTap: () => _showServerPicker(context),
                onFitTap: _cycleFit,
                onTrackTap: () => _showTrackPicker(context),
                onEpisodeTap: (ep) => _switchToEpisode(ep),
                onSeasonTap: (s) => _loadSeasonEpisodes(s),
                onPrev: _canGoPrev ? _goPrev : null,
                onNext: _canGoNext ? _goNext : null,
                onClose: () => setState(() => _showSettingsPanel = false),
              ),
            ),
        ],
      ),
    );
  }

  bool get _canGoPrev => widget.type == 'episode' &&
      _currentEpisodeList != null && _currentEpisodeIndex > 0;
  bool get _canGoNext => widget.type == 'episode' &&
      _currentEpisodeList != null && _currentEpisodeIndex < (_currentEpisodeList!.length - 1);

  void _goPrev() {
    if (!_canGoPrev) return;
    _switchToEpisode(_currentEpisodeList![_currentEpisodeIndex - 1]);
  }

  void _goNext() {
    if (!_canGoNext) return;
    _switchToEpisode(_currentEpisodeList![_currentEpisodeIndex + 1]);
  }

  void _showServerPicker(BuildContext context) {
    if (_servers == null || _servers!.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServerPickerSheet(
        servers: _servers!,
        currentServer: _currentServer,
        onSelect: (s) {
          Navigator.pop(context);
          _loadServer(s);
        },
      ),
    );
  }
}

// ─── Player Sub-Widgets ──────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  const _TopBar({required this.title, required this.onBack, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 8,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ServerPickerSheet extends StatelessWidget {
  final List<VideoServer> servers;
  final VideoServer? currentServer;
  final Function(VideoServer) onSelect;

  const _ServerPickerSheet({required this.servers, this.currentServer, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.55;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Select Server',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(color: Colors.white12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: servers.length,
                itemBuilder: (_, i) {
                  final s = servers[i];
                  final isActive = s.id == currentServer?.id;
                  return ListTile(
                    onTap: () => onSelect(s),
                    leading: Icon(Icons.dns_rounded,
                        color: isActive ? Colors.blueAccent : Colors.white54),
                    title: Text(s.name,
                        style: TextStyle(
                          color: isActive ? Colors.blueAccent : Colors.white,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        )),
                    trailing: isActive
                        ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Side Panel ──────────────────────────────────────────

class _SettingsPanel extends StatefulWidget {
  final String type;
  final double speed;
  final VideoServer? currentServer;
  final List<VideoServer>? servers;
  final List<StreamEpisode>? episodes;
  final List<StreamSeason>? seasons;
  final StreamSeason? currentSeason;
  final int currentIndex;
  
  final VoidCallback onSpeedTap;
  final VoidCallback onServerTap;
  final VoidCallback onFitTap;
  final VoidCallback onTrackTap;
  final Function(StreamEpisode) onEpisodeTap;
  final Function(StreamSeason) onSeasonTap;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onClose;
  
  final BoxFit currentFit;
  final String fitName;
  final BetterPlayerAsmsTrack? currentTrack;
  final bool hasTracks;

  const _SettingsPanel({
    required this.type,
    required this.speed,
    required this.currentServer,
    required this.servers,
    this.episodes,
    this.seasons,
    this.currentSeason,
    required this.currentIndex,
    required this.onSpeedTap,
    required this.onServerTap,
    required this.onFitTap,
    required this.onTrackTap,
    required this.currentFit,
    required this.fitName,
    required this.currentTrack,
    required this.hasTracks,
    required this.onEpisodeTap,
    required this.onSeasonTap,
    this.onPrev,
    this.onNext,
    required this.onClose,
  });

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      color: const Color(0xFF0D0D1A).withOpacity(0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 8, bottom: 4),
            child: Row(
              children: [
                const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: widget.onClose),
              ],
            ),
          ),

          // Settings Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.speed_rounded, color: Colors.white70),
                  title: const Text('Speed', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text('${widget.speed}x', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  onTap: widget.onSpeedTap,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.aspect_ratio_rounded, color: Colors.white70),
                  title: const Text('Fit Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text(widget.fitName, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  onTap: widget.onFitTap,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.dns_rounded, color: Colors.white70),
                  title: const Text('Server', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(widget.currentServer?.name ?? 'Unknown', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: widget.onServerTap,
                ),
                if (widget.hasTracks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.high_quality_rounded, color: Colors.white70),
                    title: const Text('Quality', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(widget.currentTrack?.height == 0 ? 'Auto' : '${widget.currentTrack?.height ?? 'Auto'}p', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: widget.onTrackTap,
                  ),

                if (widget.type == 'episode') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onPrev,
                          icon: const Icon(Icons.skip_previous_rounded, size: 16),
                          label: const Text('Prev'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onNext,
                          icon: const Icon(Icons.skip_next_rounded, size: 16),
                          label: const Text('Next'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          if (widget.episodes != null) ...[
            const Divider(color: Colors.white12, height: 1),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Text('Episodes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),

            // Season selector
            if (widget.seasons != null && widget.seasons!.length > 1) ...[
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.seasons!.length,
                  itemBuilder: (_, i) {
                    final s = widget.seasons![i];
                    final isSelected = s.id == widget.currentSeason?.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => widget.onSeasonTap(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            s.title ?? 'S${s.number}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white12),
            ],

            // Episode list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: widget.episodes!.length,
                itemBuilder: (_, i) {
                  final ep = widget.episodes![i];
                  final isCurrent = i == widget.currentIndex;
                  return GestureDetector(
                  onTap: () => widget.onEpisodeTap(ep),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent ? Colors.blueAccent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 72,
                            height: 42,
                            color: const Color(0xFF1A1A2E),
                            child: ep.poster != null
                                ? Image.network(ep.poster!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.play_circle_outline, color: Colors.grey, size: 20))
                                : const Icon(Icons.play_circle_outline, color: Colors.grey, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'E${ep.number}: ${ep.title}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.blueAccent : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          const Icon(Icons.play_arrow_rounded, color: Colors.blueAccent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          ],
        ],
      ),
    );
  }
}
