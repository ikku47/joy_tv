import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/streamengine/stream_models.dart';
import '../utils/log_util.dart';

class StreamEngineService {
  static const _channel = MethodChannel('com.example.joy_tv.stream_engine');

  String? _asJsonString(dynamic res) {
    if (res is String) return res;
    if (res is Map || res is List) return jsonEncode(res);
    return res?.toString();
  }

  Future<List<StreamCategory>> getHome({String? language, String? section}) async {
    try {
      final res = await _channel.invokeMethod('get_home', {
        'language': language,
        'section': section,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('get_home', jsonString, tag: 'StreamEngine');
      final List list = jsonDecode(jsonString);
      return list.map((c) => StreamCategory.fromJson(c)).toList();
    } catch (e, st) {
      logE('get_home failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<StreamItem>> getTmdbList(String endpoint, {int page = 1, String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_tmdb_list', {
        'endpoint': endpoint,
        'page': page,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('get_tmdb_list_$endpoint', jsonString, tag: 'StreamEngine');
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => StreamItem.fromJson(e)).toList();
    } catch (e, st) {
      logE('get_tmdb_list failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<StreamItem>> discover({
    required String type, // "movie" or "tv"
    required Map<String, String> params,
    int page = 1,
    String language = 'en',
  }) async {
    try {
      final res = await _channel.invokeMethod('get_tmdb_discover', {
        'type': type,
        'params': params,
        'page': page,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('discover_${type}_$page', jsonString, tag: 'StreamEngine');
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => StreamItem.fromJson(e)).toList();
    } catch (e, st) {
      logE('discover failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<StreamItem>> search(String query, {String language = 'en', int page = 1}) async {
    try {
      final res = await _channel.invokeMethod('search', {
        'query': query,
        'language': language,
        'page': page,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('search', jsonString, tag: 'StreamEngine');
      final List list = jsonDecode(jsonString);
      return list.map((i) => StreamItem.fromJson(i)).toList();
    } catch (e, st) {
      logE('search failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<StreamMovie?> getMovieDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_movie_details', {
        'id': id,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return null;
      logJson('get_movie_details', jsonString, tag: 'StreamEngine');
      return StreamMovie.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      logE('get_movie_details failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return null;
    }
  }

  Future<StreamTvShow?> getTvShowDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_tv_show_details', {
        'id': id,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return null;
      logJson('get_tv_show_details', jsonString, tag: 'StreamEngine');
      return StreamTvShow.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      logE('get_tv_show_details failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<StreamEpisode>> getEpisodes(String seasonId, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_episodes', {
        'seasonId': seasonId,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('get_episodes', jsonString, tag: 'StreamEngine');
      final List list = jsonDecode(jsonString);
      return list.map((e) => StreamEpisode.fromJson(e)).toList();
    } catch (e, st) {
      logE('get_episodes failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<StreamGenre?> getGenre(String id, {int page = 1, String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_genre', {
        'id': id,
        'page': page,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return null;
      logJson('get_genre', jsonString, tag: 'StreamEngine');
      return StreamGenre.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      logE('get_genre failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return null;
    }
  }

  Future<StreamPeople?> getPeople(String id, {int page = 1, String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_people', {
        'id': id,
        'page': page,
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return null;
      logJson('get_people', jsonString, tag: 'StreamEngine');
      return StreamPeople.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      logE('get_people failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<VideoServer>> getServers(
    String id, {
    required String type,
    String language = 'en',
    // For episodes only:
    String? tvShowId,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeId,
  }) async {
    try {
      final args = <String, dynamic>{
        'id': id,
        'type': type,
        'language': language,
      };
      if (type == 'episode') {
        args['tvShowId'] = tvShowId ?? id;
        args['seasonNumber'] = seasonNumber ?? 1;
        args['episodeNumber'] = episodeNumber ?? 1;
        args['episodeId'] = episodeId ?? '';
      }
      final res = await _channel.invokeMethod('get_servers', args);

      final jsonString = _asJsonString(res);
      if (jsonString == null) return [];
      logJson('get_servers', jsonString, tag: 'StreamEngine');
      final List list = jsonDecode(jsonString);
      return list.map((s) => VideoServer.fromJson(s)).toList();
    } catch (e, st) {
      logE('get_servers failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  Future<VideoSource?> extractVideo(VideoServer server, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('extract_video', {
        'serverJson': jsonEncode(server.toJson()),
        'language': language,
      });

      final jsonString = _asJsonString(res);
      if (jsonString == null) return null;
      logJson('extract_video', jsonString, tag: 'StreamEngine');
      return VideoSource.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      logE('extract_video failed', tag: 'StreamEngine', error: e, stackTrace: st);
      return null;
    }
  }
}
