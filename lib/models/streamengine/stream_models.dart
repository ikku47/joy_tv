import 'dart:convert';

String? _normalizeReleased(dynamic raw) {
  if (raw == null) return null;

  if (raw is String) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  if (raw is Map) {
    final year = int.tryParse(raw['year']?.toString() ?? '');
    final rawMonth = int.tryParse(raw['month']?.toString() ?? '');
    final day = int.tryParse(raw['dayOfMonth']?.toString() ?? '') ?? 1;

    if (year != null && rawMonth != null) {
      // Kotlin Calendar month is usually 0-based in this payload.
      final month = (rawMonth >= 0 && rawMonth <= 11) ? rawMonth + 1 : rawMonth;
      final mm = month.toString().padLeft(2, '0');
      final dd = day.toString().padLeft(2, '0');
      return '$year-$mm-$dd';
    }
  }

  return raw.toString();
}

class StreamCategory {
  final String name;
  final List<StreamItem> items;

  StreamCategory({required this.name, required this.items});

  factory StreamCategory.fromJson(Map<String, dynamic> json) {
    var list = json['list'] as List;
    return StreamCategory(
      name: json['name'] ?? '',
      items: list.map((i) => StreamItem.fromJson(i)).toList(),
    );
  }
}

abstract class StreamItem {
  String get id;
  String get title;
  String? get poster;
  String? get banner;
  double? get rating;
  String? get released;

  factory StreamItem.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('episodes') || json.containsKey('seasons')) {
      return StreamTvShow.fromJson(json);
    } else {
      return StreamMovie.fromJson(json);
    }
  }
}

class StreamMovie implements StreamItem {
  @override
  final String id;
  @override
  final String title;
  final String? overview;
  @override
  final String? poster;
  @override
  final String? banner;
  @override
  final double? rating;
  @override
  final String? released;
  final int? runtime;
  final String? trailer;

  final List<StreamPeople>? cast;
  final List<StreamItem>? recommendations;

  StreamMovie({
    required this.id,
    required this.title,
    this.overview,
    this.poster,
    this.banner,
    this.rating,
    this.released,
    this.runtime,
    this.trailer,
    this.cast,
    this.recommendations,
  });

  factory StreamMovie.fromJson(Map<String, dynamic> json) {
    return StreamMovie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      overview: json['overview']?.toString(),
      poster: json['poster']?.toString(),
      banner: json['banner']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      released: _normalizeReleased(json['released']),
      runtime: json['runtime'] is int ? json['runtime'] : null,
      trailer: json['trailer']?.toString(),
      cast: (json['cast'] as List?)?.map((p) => StreamPeople.fromJson(p)).toList(),
      recommendations: (json['recommendations'] as List?)?.map((i) => StreamItem.fromJson(i)).toList(),
    );
  }
}

class StreamTvShow implements StreamItem {
  @override
  final String id;
  @override
  final String title;
  final String? overview;
  @override
  final String? poster;
  @override
  final String? banner;
  @override
  final double? rating;
  @override
  final String? released;
  final List<StreamSeason>? seasons;
  final List<StreamPeople>? cast;
  final List<StreamItem>? recommendations;

  StreamTvShow({
    required this.id,
    required this.title,
    this.overview,
    this.poster,
    this.banner,
    this.rating,
    this.released,
    this.seasons,
    this.cast,
    this.recommendations,
  });

  factory StreamTvShow.fromJson(Map<String, dynamic> json) {
    var seasonsList = json['seasons'] as List?;
    return StreamTvShow(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      overview: json['overview']?.toString(),
      poster: json['poster']?.toString(),
      banner: json['banner']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      released: _normalizeReleased(json['released']),
      seasons: seasonsList?.map((s) => StreamSeason.fromJson(s)).toList(),
      cast: (json['cast'] as List?)?.map((p) => StreamPeople.fromJson(p)).toList(),
      recommendations: (json['recommendations'] as List?)?.map((i) => StreamItem.fromJson(i)).toList(),
    );
  }
}

class StreamSeason {
  final String id;
  final int number;
  final String? title;
  final String? poster;

  StreamSeason({
    required this.id,
    required this.number,
    this.title,
    this.poster,
  });

  factory StreamSeason.fromJson(Map<String, dynamic> json) {
    return StreamSeason(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? 0,
      title: json['title']?.toString(),
      poster: json['poster']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'poster': poster,
  };
}

class StreamEpisode {
  final String id;
  final int number;
  final String title;
  final String? overview;
  final String? released;
  final String? poster;

  StreamEpisode({
    required this.id,
    required this.number,
    required this.title,
    this.overview,
    this.released,
    this.poster,
  });

  factory StreamEpisode.fromJson(Map<String, dynamic> json) {
    return StreamEpisode(
      id: json['id']?.toString() ?? '',
      number: json['number'] ?? 0,
      title: json['title']?.toString() ?? '',
      overview: json['overview']?.toString(),
      released: _normalizeReleased(json['released']),
      poster: json['poster']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'overview': overview,
    'released': released,
    'poster': poster,
  };
}

class VideoServer {
  final String id;
  final String name;
  final String src; // maps to Video.Server.src in Kotlin

  VideoServer({required this.id, required this.name, required this.src});

  // Kotlin serializes Video.Server with fields: id, name, src
  factory VideoServer.fromJson(Map<String, dynamic> json) {
    return VideoServer(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      src: json['src']?.toString() ?? json['link']?.toString() ?? '',
    );
  }

  // Must match what Kotlin's GSON expects for Video.Server deserialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'src': src,
  };
}

class VideoSource {
  final String source;
  final String? type;
  final Map<String, String>? headers;

  VideoSource({required this.source, this.type, this.headers});

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      source: json['source'] ?? '',
      type: json['type'],
      headers: (json['headers'] as Map?)?.cast<String, String>(),
    );
  }
}

class StreamPeople {
  final String id;
  final String name;
  final String? image;

  StreamPeople({required this.id, required this.name, this.image});

  factory StreamPeople.fromJson(Map<String, dynamic> json) {
    return StreamPeople(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }
}
