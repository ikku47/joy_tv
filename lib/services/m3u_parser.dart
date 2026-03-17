import '../models/iptv_channel.dart';

class M3UParser {
  static List<IPTVChannel> parse(String content) {
    final List<IPTVChannel> channels = [];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;

    final regex = RegExp(r'#EXTINF:-1|tvg-id="([^"]*)"|tvg-name="([^"]*)"|tvg-logo="([^"]*)"|group-title="([^"]*)",(.*)');

    int? currentNumber;
    int nextDefaultNumber = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Simple regex parsing for speed
        final tvgIdMatch = RegExp(r'tvg-id="([^"]*)"').firstMatch(line);
        final tvgNameMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(line);
        final tvgLogoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        final tvgChNoMatch = RegExp(r'tvg-chno="([^"]*)"').firstMatch(line);
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        
        // Channel name is usually after the last comma
        final nameParts = line.split(',');
        currentName = nameParts.length > 1 ? nameParts.last.trim() : 'Unknown Channel';
        
        currentTvgId = tvgIdMatch?.group(1);
        currentTvgName = tvgNameMatch?.group(1);
        currentLogo = tvgLogoMatch?.group(1);
        currentGroup = groupMatch?.group(1);
        
        if (tvgChNoMatch != null) {
          currentNumber = int.tryParse(tvgChNoMatch.group(1) ?? '');
        }
      } else if (!line.startsWith('#')) {
        // This is the URL
        if (currentName != null) {
          channels.add(IPTVChannel(
            name: currentName,
            url: line,
            logo: currentLogo,
            number: currentNumber ?? nextDefaultNumber++,
            group: currentGroup,
            tvgId: currentTvgId,
            tvgName: currentTvgName,
          ));
        }
        // Reset for next channel
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
        currentNumber = null;
      }
    }

    return channels;
  }
}
