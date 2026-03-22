import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/streamengine/stream_models.dart';

class StreamEngineService {
  static const _channel = MethodChannel('com.example.joy_tv.stream_engine');
  
  Future<List<StreamCategory>> getHome({String? language, String? section}) async {
    try {
      final res = await _channel.invokeMethod('get_home', {
        'language': language,
        'section': section,
      });
      print('StreamEngine getHome result type: ${res.runtimeType}');
      
      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return [];
      print('StreamEngine JSON Start: ${jsonString.substring(0, 500.clamp(0, jsonString.length))}');
      final List list = jsonDecode(jsonString);
      return list.map((c) => StreamCategory.fromJson(c)).toList();
    } catch (e) {
      print('StreamEngine ERROR: $e');
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

      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return [];
      final List list = jsonDecode(jsonString);
      return list.map((i) => StreamItem.fromJson(i)).toList();
    } catch (e) {
      print('StreamEngine SEARCH ERROR: $e');
      return [];
    }
  }

  Future<StreamMovie?> getMovieDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_movie_details', {
        'id': id,
        'language': language,
      });
      
      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return null;
      return StreamMovie.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('StreamEngine MOVIE ERROR: $e');
      return null;
    }
  }

  Future<StreamTvShow?> getTvShowDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_tv_show_details', {
        'id': id,
        'language': language,
      });

      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return null;
      return StreamTvShow.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('StreamEngine TV ERROR: $e');
      return null;
    }
  }

  Future<List<StreamEpisode>> getEpisodes(String seasonId, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('get_episodes', {
        'seasonId': seasonId,
        'language': language,
      });

      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return [];
      final List list = jsonDecode(jsonString);
      return list.map((e) => StreamEpisode.fromJson(e)).toList();
    } catch (e) {
      print('StreamEngine EPISODES ERROR: $e');
      return [];
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

      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return [];
      final List list = jsonDecode(jsonString);
      return list.map((s) => VideoServer.fromJson(s)).toList();
    } catch (e) {
      print('StreamEngine SERVERS ERROR: $e');
      return [];
    }
  }

  Future<VideoSource?> extractVideo(VideoServer server, {String language = 'en'}) async {
    try {
      final res = await _channel.invokeMethod('extract_video', {
        'serverJson': jsonEncode(server.toJson()),
        'language': language,
      });

      String? jsonString;
      if (res is String) {
        jsonString = res;
      } else if (res is Map || res is List) {
        jsonString = jsonEncode(res);
      } else {
        jsonString = res?.toString();
      }

      if (jsonString == null) return null;
      return VideoSource.fromJson(jsonDecode(jsonString));
    } catch (e) {
      print('StreamEngine EXTRACTION ERROR: $e');
      return null;
    }
  }
}
