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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'logo': logo,
      'number': number,
      'group': group,
      'tvgId': tvgId,
      'tvgName': tvgName,
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
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}

