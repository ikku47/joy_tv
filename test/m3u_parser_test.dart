import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tv/services/m3u_parser.dart';
import 'package:joy_tv/models/iptv_channel.dart';

void main() {
  group('M3UParser Tests', () {
    test('should parse tvg-chno when present', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="id1" tvg-name="Channel 1" tvg-logo="logo1.png" tvg-chno="5" group-title="Group 1",Channel 1
http://example.com/ch1.m3u8
''';
      final channels = M3UParser.parse(content);
      expect(channels.length, 1);
      expect(channels[0].number, 5);
      expect(channels[0].name, 'Channel 1');
    });

    test('should assign sequential numbers when tvg-chno is missing', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="id1" tvg-name="Channel 1",Channel 1
http://example.com/ch1.m3u8
#EXTINF:-1 tvg-id="id2" tvg-name="Channel 2",Channel 2
http://example.com/ch2.m3u8
''';
      final channels = M3UParser.parse(content);
      expect(channels.length, 2);
      expect(channels[0].number, 1);
      expect(channels[1].number, 2);
    });

    test('should mix tvg-chno and sequential numbers correctly', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="id1",Channel 1
http://example.com/ch1.m3u8
#EXTINF:-1 tvg-id="id2" tvg-chno="10",Channel 2
http://example.com/ch2.m3u8
#EXTINF:-1 tvg-id="id3",Channel 3
http://example.com/ch3.m3u8
''';
      final channels = M3UParser.parse(content);
      expect(channels.length, 3);
      expect(channels[0].number, 1);
      expect(channels[1].number, 10);
      expect(
        channels[2].number,
        2,
      ); // Sequential continues from last assigned sequential number
    });

    test('should parse supported custom directives between EXTINF and url', () {
      const content = '''
#EXTM3U x-tvg-url="https://example.com/epg.xml"
#EXTINF:-1 tvg-id="id1" tvg-name="Channel 1" tvg-logo="logo1.png" group-title="Group 1",Channel 1
#EXTVLCOPT:http-referrer=https://example.com
#EXTVLCOPT:http-user-agent=JoyTVTest/1.0
#EXTVLCOPT:http-origin=https://origin.example.com
#KODIPROP:inputstreamaddon=inputstream.adaptive
#KODIPROP:inputstream.adaptive.license_type=clearkey
#EXT-X-APP APTV
#EXT-X-APTV-TYPE remote
#EXT-X-SUB-URL https://example.com/sub.m3u
http://example.com/ch1.m3u8
''';

      final channels = M3UParser.parse(content);
      expect(channels.length, 1);
      expect(channels[0].headers?['Referer'], 'https://example.com');
      expect(channels[0].headers?['User-Agent'], 'JoyTVTest/1.0');
      expect(channels[0].headers?['Origin'], 'https://origin.example.com');
      expect(
        channels[0].kodiProps?['inputstreamaddon'],
        'inputstream.adaptive',
      );
      expect(
        channels[0].kodiProps?['inputstream.adaptive.license_type'],
        'clearkey',
      );
      expect(channels[0].aptvProps?['#EXT-X-APP'], 'APTV');
      expect(channels[0].aptvProps?['#EXT-X-APTV-TYPE'], 'remote');
      expect(
        channels[0].aptvProps?['#EXT-X-SUB-URL'],
        'https://example.com/sub.m3u',
      );
      expect(channels[0].extraDirectives, hasLength(8));
    });

    test(
      'should ignore comment style hash lines without breaking channel parsing',
      () {
        const content = '''
#EXTM3U
# Made by Example
#=================================
#EXTINF:-1,Channel 1
#http://commented-out.example.com/live.m3u8
http://example.com/ch1.m3u8
''';

        final channels = M3UParser.parse(content);
        expect(channels.length, 1);
        expect(channels[0].name, 'Channel 1');
        expect(channels[0].url, 'http://example.com/ch1.m3u8');
        expect(channels[0].extraDirectives, isNull);
      },
    );
  });
}
