import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/iptv_channel.dart';
import 'm3u_parser.dart';
import '../utils/log_util.dart';

class PlaylistCacheService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  Future<List<IPTVPlaylistSource>> getSources() async {
    try {
      final String response = await rootBundle.loadString('assets/playlists.json');
      final data = await json.decode(response) as List;
      return data.map((e) => IPTVPlaylistSource.fromJson(e)).toList();
    } catch (e) {
      logE('Error loading sources', tag: 'PlaylistCache', error: e);
      return [];
    }
  }

  Future<List<IPTVChannel>> fetchPlaylist(IPTVPlaylistSource source) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(source.id);
      
      if (fileInfo != null && fileInfo.validTill.isAfter(DateTime.now())) {
        logD('Loading ${source.name} from cache', tag: 'PlaylistCache');
        final content = await fileInfo.file.readAsString();
        return M3UParser.parse(content);
      }

      logD('Fetching ${source.name} from network', tag: 'PlaylistCache');
      final response = await http.get(Uri.parse(source.url));
      
      if (response.statusCode == 200) {
        // Cache for 24 hours
        await _cacheManager.putFile(
          source.id,
          response.bodyBytes,
          maxAge: const Duration(hours: 24),
          fileExtension: 'm3u',
        );
        return M3UParser.parse(response.body);
      } else {
        logW('Failed to fetch playlist: ${response.statusCode}', tag: 'PlaylistCache');
        return [];
      }
    } catch (e) {
      logE(
        'Error fetching playlist ${source.name}',
        tag: 'PlaylistCache',
        error: e,
      );
      return [];
    }
  }

  /// Background refresh for all sources
  Future<void> refreshAll() async {
    final sources = await getSources();
    for (var source in sources) {
      await fetchPlaylist(source);
    }
  }
}
