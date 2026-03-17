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
      expect(channels[2].number, 2); // Sequential continues from last assigned sequential number
    });
  });
}
