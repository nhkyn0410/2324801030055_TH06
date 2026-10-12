import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lyrics.dart';
import '../models/song.dart';

class LyricsService {
  LyricsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Lyrics?> _cache = {};

  static final _brackets = RegExp(r'[\(\[][^\)\]]*[\)\]]');
  static final _featuring = RegExp(
    r'\s+(feat|ft)\.?\s.*$',
    caseSensitive: false,
  );
  static final _nonWord = RegExp(r'[^a-z0-9]+');

  Future<Lyrics?> fetch(Song song) async {
    if (_cache.containsKey(song.id)) return _cache[song.id];
    final lyrics = await _load(song);
    _cache[song.id] = lyrics;
    return lyrics;
  }

  Future<Lyrics?> _load(Song song) async {
    final (title, artist) = cleanQuery(song.title, song.artist);
    if (title.isEmpty) return null;
    final uri = Uri.https('lrclib.net', '/api/search', {
      'track_name': title,
      'artist_name': artist,
    });
    final response = await _client
        .get(uri, headers: {'User-Agent': 'th06_music student project'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! List) return null;

    String? plain;
    for (final item in body.whereType<Map>()) {
      final duration = (item['duration'] as num?)?.toDouble() ?? 0;
      final diff = (duration - song.durationSeconds).abs();
      final synced = item['syncedLyrics'];
      if (synced is String && synced.trim().isNotEmpty && diff <= 3) {
        final lyrics = Lyrics.fromLrc(synced);
        if (lyrics.lines.isNotEmpty) return lyrics;
      }
      final text = item['plainLyrics'];
      if (plain == null && text is String && text.trim().isNotEmpty) {
        plain = text;
      }
    }
    return plain == null ? null : Lyrics.fromPlain(plain);
  }

  static (String, String) cleanQuery(String rawTitle, String rawArtist) {
    var title = rawTitle.replaceAll(_brackets, ' ').trim();
    var artist = rawArtist.trim();
    final dash = title.indexOf(' - ');
    if (dash > 0) {
      final left = title.substring(0, dash).trim();
      final right = title.substring(dash + 3).trim();
      final a = _normalize(left);
      final b = _normalize(artist);
      final sameArtist =
          a.isNotEmpty && b.isNotEmpty && (a.contains(b) || b.contains(a));
      if (!sameArtist) artist = left;
      title = right;
    }
    title = title.replaceAll(_featuring, '').trim();
    return (title, artist);
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(_nonWord, '');
  }
}
