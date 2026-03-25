class IPTVChannel {
  final String name;
  final String url;
  final String? logo;
  final int? number;
  final String? group;
  final String? tvgId;
  final String? tvgName;
  final Map<String, String>? headers;
  final Map<String, String>? kodiProps;
  final Map<String, String>? aptvProps;
  final List<String>? extraDirectives;

  IPTVChannel({
    required this.name,
    required this.url,
    this.logo,
    this.number,
    this.group,
    this.tvgId,
    this.tvgName,
    this.headers,
    this.kodiProps,
    this.aptvProps,
    this.extraDirectives,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'logo': logo,
      'number': number,
      'group': group,
      'tvgId': tvgId,
      'tvgName': tvgName,
      'headers': headers,
      'kodiProps': kodiProps,
      'aptvProps': aptvProps,
      'extraDirectives': extraDirectives,
    };
  }

  factory IPTVChannel.fromJson(Map<String, dynamic> json) {
    return IPTVChannel(
      name: json['name'],
      url: json['url'],
      logo: json['logo'],
      number: json['number'],
      group: json['group'],
      tvgId: json['tvgId'],
      tvgName: json['tvgName'],
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'])
          : null,
      kodiProps: json['kodiProps'] != null
          ? Map<String, String>.from(json['kodiProps'])
          : null,
      aptvProps: json['aptvProps'] != null
          ? Map<String, String>.from(json['aptvProps'])
          : null,
      extraDirectives: json['extraDirectives'] != null
          ? List<String>.from(json['extraDirectives'])
          : null,
    );
  }

  @override
  String toString() => 'IPTVChannel(name: $name, group: $group)';
}

class IPTVPlaylistSource {
  final String id;
  final String name;
  final String url;

  IPTVPlaylistSource({required this.id, required this.name, required this.url});

  factory IPTVPlaylistSource.fromJson(Map<String, dynamic> json) {
    return IPTVPlaylistSource(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'url': url};
  }
}
