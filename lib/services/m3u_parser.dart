import '../models/iptv_channel.dart';

class M3UParser {
  static final RegExp _quotedAttributePattern = RegExp(r'([\w-]+)="([^"]*)"');
  static final RegExp _directivePattern = RegExp(r'^(#[^:,\s]+)');

  static List<IPTVChannel> parse(String content) {
    final List<IPTVChannel> channels = [];
    final lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentTvgId;
    String? currentTvgName;

    Map<String, String>? currentHeaders;
    Map<String, String>? currentKodiProps;
    Map<String, String>? currentAptvProps;
    List<String>? currentExtraDirectives;
    int? currentNumber;
    int nextDefaultNumber = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final attributes = _parseQuotedAttributes(line);

        // Channel name is usually after the last comma
        final nameParts = line.split(',');
        currentName = nameParts.length > 1
            ? nameParts.last.trim()
            : 'Unknown Channel';

        currentTvgId = attributes['tvg-id'];
        currentTvgName = attributes['tvg-name'];
        currentLogo = attributes['tvg-logo'];
        currentGroup = attributes['group-title'];

        final tvgChNo = attributes['tvg-chno'];
        if (tvgChNo != null) {
          currentNumber = int.tryParse(tvgChNo);
        }
      } else if (line.startsWith('#EXTVLCOPT:')) {
        final opt = line.substring(11).trim();
        final separatorIndex = opt.indexOf('=');
        if (separatorIndex == -1) continue;

        final key = opt.substring(0, separatorIndex).trim();
        final value = opt.substring(separatorIndex + 1).trim();
        if (value.isEmpty) continue;

        currentExtraDirectives ??= [];
        currentExtraDirectives!.add(line);

        currentHeaders ??= {};
        switch (key.toLowerCase()) {
          case 'http-referrer':
          case 'http-referer':
            currentHeaders!['Referer'] = value;
            break;
          case 'http-user-agent':
            currentHeaders!['User-Agent'] = value;
            break;
          case 'http-origin':
            currentHeaders!['Origin'] = value;
            break;
          case 'http-cookie':
            currentHeaders!['Cookie'] = value;
            break;
          default:
            break;
        }
      } else if (line.startsWith('#KODIPROP:')) {
        final prop = line.substring(10).trim();
        final separatorIndex = prop.indexOf('=');
        if (separatorIndex == -1) continue;
        final key = prop.substring(0, separatorIndex).trim();
        final value = prop.substring(separatorIndex + 1).trim();
        if (key.isEmpty || value.isEmpty) continue;

        currentKodiProps ??= {};
        currentKodiProps![key] = value;
        currentExtraDirectives ??= [];
        currentExtraDirectives!.add(line);
      } else if (line.startsWith('#EXT-X-')) {
        final directive = _directivePattern.firstMatch(line)?.group(1);
        if (directive == null) continue;

        final value = _extractDirectiveValue(line, directive);
        currentAptvProps ??= {};
        currentAptvProps![directive] = value;
        currentExtraDirectives ??= [];
        currentExtraDirectives!.add(line);
      } else if (line.startsWith('#')) {
        // Ignore comments and unsupported custom markers without breaking parsing.
        continue;
      } else {
        // This is the URL
        if (currentName != null) {
          channels.add(
            IPTVChannel(
              name: currentName,
              url: line,
              logo: currentLogo,
              number: currentNumber ?? nextDefaultNumber++,
              group: currentGroup,
              tvgId: currentTvgId,
              tvgName: currentTvgName,
              headers: currentHeaders != null
                  ? Map.from(currentHeaders!)
                  : null,
              kodiProps: currentKodiProps != null
                  ? Map.from(currentKodiProps!)
                  : null,
              aptvProps: currentAptvProps != null
                  ? Map.from(currentAptvProps!)
                  : null,
              extraDirectives: currentExtraDirectives != null
                  ? List<String>.from(currentExtraDirectives!)
                  : null,
            ),
          );
        }
        // Reset for next channel
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentTvgId = null;
        currentTvgName = null;
        currentNumber = null;
        currentHeaders = null;
        currentKodiProps = null;
        currentAptvProps = null;
        currentExtraDirectives = null;
      }
    }

    return channels;
  }

  static Map<String, String> _parseQuotedAttributes(String line) {
    final attributes = <String, String>{};
    for (final match in _quotedAttributePattern.allMatches(line)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        attributes[key] = value;
      }
    }
    return attributes;
  }

  static String _extractDirectiveValue(String line, String directive) {
    if (line.length <= directive.length) return '';
    var remainder = line.substring(directive.length).trimLeft();
    if (remainder.startsWith(':')) {
      remainder = remainder.substring(1).trimLeft();
    }
    return remainder;
  }
}
