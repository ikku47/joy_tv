import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/iptv_channel.dart';
import 'playlist_cache_service.dart';
import 'dart:developer' as dev;

class PlaylistMergeService {
  static const String _lastSyncKey = 'last_playlist_sync';
  static const String _combinedFileName = 'combined_playlist.json';
  
  final PlaylistCacheService _cacheService = PlaylistCacheService();

  // Progress notification callback
  void Function(double progress, String message)? onProgress;

  Future<bool> shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    if (lastSyncStr == null) return true;
    
    try {
      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      // Sync once a day
      return now.difference(lastSync).inDays >= 1;
    } catch (e) {
      return true;
    }
  }

  Future<void> markSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<bool> hasLocalPlaylist() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_combinedFileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<List<IPTVChannel>> getLocalPlaylist() async {

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_combinedFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        return jsonList.map((e) => IPTVChannel.fromJson(e)).toList();
      }
    } catch (e) {
      dev.log('Error loading local playlist: $e');
    }
    return [];
  }

  Future<List<IPTVChannel>> syncPlaylists() async {
    final sources = await _cacheService.getSources();
    List<IPTVChannel> allChannels = [];
    
    onProgress?.call(0.05, 'Fetching sources...');
    
    for (int i = 0; i < sources.length; i++) {
      final source = sources[i];
      onProgress?.call(0.05 + (0.10 * (i / sources.length)), 'Fetching ${source.name}...');
      final channels = await _cacheService.fetchPlaylist(source);
      allChannels.addAll(channels);
    }

    // Deduplicate by URL BEFORE validation to save time
    onProgress?.call(0.15, 'Deduplicating ${allChannels.length} channels...');
    final Map<String, IPTVChannel> uniqueMap = {};
    for (var channel in allChannels) {
      // Use URL as key to deduplicate
      uniqueMap[channel.url] = channel;
    }
    final List<IPTVChannel> dedupedChannels = uniqueMap.values.toList();
    
    onProgress?.call(0.2, 'Validating ${dedupedChannels.length} unique channels...');
    
    // Validate URLs in parallel with limited concurrency
    final client = http.Client();
    try {
      final validatedChannels = await _filterWorkingChannels(dedupedChannels, client);
      
      onProgress?.call(0.95, 'Saving playlist...');
      
      // Save to local file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_combinedFileName');
      await file.writeAsString(json.encode(validatedChannels.map((e) => e.toJson()).toList()));
      
      await markSynced();
      onProgress?.call(1.0, 'Done!');
      
      return validatedChannels;
    } finally {
      client.close();
    }
  }

  Future<List<IPTVChannel>> _filterWorkingChannels(List<IPTVChannel> channels, http.Client client) async {
    const int concurrency = 100; // Increased concurrency for 42k list
    final List<IPTVChannel> workingChannels = [];
    int checkedCount = 0;
    
    for (int i = 0; i < channels.length; i += concurrency) {
      final chunk = channels.skip(i).take(concurrency).toList();
      final results = await Future.wait(chunk.map((channel) async {
        final isWorking = await _isUrlWorking(channel.url, client);
        return isWorking ? channel : null;
      }));
      
      workingChannels.addAll(results.whereType<IPTVChannel>());
      checkedCount += chunk.length;
      
      final double progress = 0.2 + (0.75 * (checkedCount / channels.length));
      onProgress?.call(
        progress, 
        'Checked $checkedCount/${channels.length} (${workingChannels.length} alive)'
      );
    }
    
    return workingChannels;
  }

  Future<bool> _isUrlWorking(String url, http.Client client) async {
    try {
      final uri = Uri.parse(url);
      // Use a shorter timeout for HEAD (1.5s) to keep things moving
      final response = await client.head(uri).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode >= 200 && response.statusCode < 400) return true;
      
      // Some servers block HEAD but allow GET
      // Only try GET if HEAD failed fast
      final getResponse = await client.get(uri).timeout(const Duration(milliseconds: 1500));
      return getResponse.statusCode >= 200 && getResponse.statusCode < 400;
    } catch (e) {
      return false;
    }
  }
}

