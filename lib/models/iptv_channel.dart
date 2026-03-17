class IPTVChannel {
  final String name;
  final String url;
  final String? logo;
  final int? number;
  final String? group;
  final String? tvgId;
  final String? tvgName;

  IPTVChannel({
    required this.name,
    required this.url,
    this.logo,
    this.number,
    this.group,
    this.tvgId,
    this.tvgName,
  });

  @override
  String toString() => 'IPTVChannel(name: $name, group: $group)';
}

class IPTVPlaylistSource {
  final String id;
  final String name;
  final String url;

  IPTVPlaylistSource({
    required this.id,
    required this.name,
    required this.url,
  });

  factory IPTVPlaylistSource.fromJson(Map<String, dynamic> json) {
    return IPTVPlaylistSource(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}
