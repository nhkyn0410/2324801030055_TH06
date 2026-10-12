import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/audius_api.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api) {
    load();
  }

  final AudiusApi _api;

  List<Song> _songs = const [];
  bool _loading = false;
  String? _error;
  String _genre = '';
  String _query = '';
  Timer? _debounce;
  int _request = 0;

  List<Song> get songs => _songs;
  bool get loading => _loading;
  String? get error => _error;
  String get genre => _genre;
  String get query => _query;
  bool get searching => _query.isNotEmpty;

  String get title {
    if (_query.isNotEmpty) return 'Kết quả tìm kiếm';
    if (_genre.isEmpty) return 'Thịnh hành tuần này';
    return 'Nổi bật thể loại $_genre';
  }

  void setQuery(String value) {
    final query = value.trim();
    if (query == _query) return;
    _query = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), load);
    notifyListeners();
  }

  void setGenre(String genre) {
    if (genre == _genre) return;
    _genre = genre;
    load();
  }

  Future<void> load() async {
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = _query.isNotEmpty
          ? await _api.search(_query)
          : await _api.trending(genre: _genre);
      if (request != _request) return;
      final seen = <String>{};
      _songs = result.where((s) => seen.add(s.id)).toList();
    } on ApiException catch (e) {
      if (request != _request) return;
      _error = e.message;
    } catch (_) {
      if (request != _request) return;
      _error = 'Đã xảy ra lỗi khi tải danh sách bài hát';
    }
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
