class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkSmall,
    required this.artworkLarge,
    required this.durationSeconds,
    this.genre = '',
    this.playCount = 0,
  });

  final String id;
  final String title;
  final String artist;
  final String artworkSmall;
  final String artworkLarge;
  final int durationSeconds;
  final String genre;
  final int playCount;

  Duration get duration => Duration(seconds: durationSeconds);

  static bool isPlayable(Map<String, dynamic> json) {
    final access = json['access'];
    final canStream = access is Map ? access['stream'] != false : true;
    return json['is_streamable'] == true &&
        json['is_stream_gated'] != true &&
        json['is_delete'] != true &&
        json['is_available'] != false &&
        canStream;
  }

  factory Song.fromAudius(Map<String, dynamic> json) {
    final artwork = json['artwork'];
    final user = json['user'];
    String art(String size) =>
        artwork is Map ? (artwork[size] as String? ?? '') : '';
    return Song(
      id: json['id'].toString(),
      title: (json['title'] as String? ?? '').trim(),
      artist: user is Map ? (user['name'] as String? ?? '').trim() : '',
      artworkSmall: art('150x150'),
      artworkLarge: art('480x480'),
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      genre: json['genre'] as String? ?? '',
      playCount: (json['play_count'] as num?)?.toInt() ?? 0,
    );
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      artworkSmall: map['artworkSmall'] as String? ?? '',
      artworkLarge: map['artworkLarge'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      genre: map['genre'] as String? ?? '',
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkSmall': artworkSmall,
      'artworkLarge': artworkLarge,
      'durationSeconds': durationSeconds,
      'genre': genre,
      'playCount': playCount,
    };
  }
}
