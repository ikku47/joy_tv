import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:developer' as dev;

import '../models/iptv_channel.dart';
import 'm3u_parser.dart';

class PlaylistCacheService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  Future<List<IPTVPlaylistSource>> getSources() async {
    try {
      final String response = await rootBundle.loadString('assets/playlists.json');
      final data = await json.decode(response) as List;
      return data.map((e) => IPTVPlaylistSource.fromJson(e)).toList();
    } catch (e) {
      dev.log("Error loading sources: $e");
      return [];
    }
  }

  Future<List<IPTVChannel>> fetchPlaylist(IPTVPlaylistSource source) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(source.id);
      
      if (fileInfo != null && fileInfo.validTill.isAfter(DateTime.now())) {
        dev.log("Loading ${source.name} from cache");
        final content = await fileInfo.file.readAsString();
        return M3UParser.parse(content);
      }

      dev.log("Fetching ${source.name} from network");
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
        dev.log("Failed to fetch playlist: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      dev.log("Error fetching playlist ${source.name}: $e");
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
