import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/song.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AudiusApi {
  AudiusApi({http.Client? client}) : _client = client ?? http.Client();

  static const appName = 'th06_music';
  static const _host = 'api.audius.co';
  static const genres = [
    'Pop',
    'Hip-Hop/Rap',
    'R&B/Soul',
    'Electronic',
    'Lo-Fi',
    'Rock',
    'Alternative',
    'Acoustic',
    'Jazz',
    'House',
  ];

  final http.Client _client;

  static String streamUrl(String id) {
    return Uri.https(_host, '/v1/tracks/$id/stream', {
      'app_name': appName,
    }).toString();
  }

  Future<List<Song>> trending({String genre = '', int limit = 50}) {
    return _tracks('/v1/tracks/trending', {
      'limit': '$limit',
      'time': genre.isEmpty ? 'week' : 'allTime',
      if (genre.isNotEmpty) 'genre': genre,
    });
  }

  Future<List<Song>> search(String query, {int limit = 50}) {
    return _tracks('/v1/tracks/search', {'query': query, 'limit': '$limit'});
  }

  Future<List<Song>> _tracks(String path, Map<String, String> params) async {
    final uri = Uri.https(_host, path, {...params, 'app_name': appName});
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw ApiException('Máy chủ trả về lỗi ${response.statusCode}');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final data = body is Map ? body['data'] : null;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where(Song.isPlayable)
          .map(Song.fromAudius)
          .where((s) => s.id.isNotEmpty && s.title.isNotEmpty)
          .toList();
    } on SocketException {
      throw const ApiException('Không có kết nối mạng');
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu');
    } on FormatException {
      throw const ApiException('Dữ liệu trả về không hợp lệ');
    } on http.ClientException {
      throw const ApiException('Không kết nối được tới máy chủ');
    }
  }
}
