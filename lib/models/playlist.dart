import 'song.dart';

class Playlist {
  const Playlist({required this.id, required this.name, required this.songs});

  final String id;
  final String name;
  final List<Song> songs;

  bool contains(String songId) => songs.any((s) => s.id == songId);

  factory Playlist.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['songs'];
    return Playlist(
      id: id,
      name: map['name'] as String? ?? '',
      songs: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Song.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}
