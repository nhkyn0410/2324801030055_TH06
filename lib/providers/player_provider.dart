import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';
import '../services/audius_api.dart';
import '../utils/app_messenger.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider() {
    _subs = [
      _player.playerStateStream.listen(_onState),
      _player.sequenceStateStream.listen((_) => _notify()),
      _player.currentIndexStream.listen((_) => _notify()),
      _player.durationStream.listen((_) => _notify()),
      _player.loopModeStream.listen((_) => _notify()),
      _player.shuffleModeEnabledStream.listen((_) => _notify()),
      _player.errorStream.listen((e) => _fail(e.index)),
    ];
  }

  final AudioPlayer _player = AudioPlayer();
  late final List<StreamSubscription<dynamic>> _subs;

  List<Song> _queue = const [];
  String _queueTitle = '';
  int? _pendingIndex;
  int _request = 0;
  int _failedRequest = -1;
  int _failures = 0;
  bool _rewinding = false;
  bool _disposed = false;

  List<Song> get queue => _queue;
  String get queueTitle => _queueTitle;

  int? get currentIndex {
    final index = _pendingIndex ?? _player.currentIndex;
    return index != null && index < _queue.length ? index : null;
  }

  Song? get currentSong {
    final index = currentIndex;
    return index == null ? null : _queue[index];
  }

  bool get playing => _player.playing;
  bool get shuffle => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  Duration get position => _player.position;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedStream => _player.bufferedPositionStream;

  bool get loading {
    final state = _player.processingState;
    return _pendingIndex != null ||
        state == ProcessingState.loading ||
        state == ProcessingState.buffering;
  }

  bool get switching => _pendingIndex != null;

  bool get audible =>
      _player.playing && _player.processingState == ProcessingState.ready;

  Duration get duration {
    final actual = _pendingIndex == null ? _player.duration : null;
    return actual ?? currentSong?.duration ?? Duration.zero;
  }

  Future<void> playSongs(
    List<Song> songs,
    int index, {
    String title = '',
    bool? shuffle,
  }) async {
    if (songs.isEmpty) return;
    _queueTitle = title;
    _failures = 0;
    if (shuffle != null && shuffle != _player.shuffleModeEnabled) {
      await _player.setShuffleModeEnabled(shuffle);
    }
    if (_sameQueue(songs)) {
      await _jump(index);
    } else {
      _queue = List.unmodifiable(songs);
      await _load(index);
    }
  }

  Future<void> playAt(int index) => _jump(index);

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (_queue.isEmpty) return;
    if (_player.processingState == ProcessingState.idle) {
      await _load(currentIndex ?? 0);
      return;
    }
    unawaited(_player.play());
  }

  Future<void> next() async {
    final target = _relative(1);
    if (target != null) await _jump(target);
  }

  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    final target = _relative(-1);
    if (target != null) await _jump(target);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) await _player.shuffle();
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> cycleLoopMode() async {
    final next = switch (_player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(next);
  }

  Future<void> playNext(Song song) async {
    final current = currentIndex;
    if (_queue.isEmpty || current == null) {
      await playSongs([song], 0, title: 'Hàng chờ');
      return;
    }
    if (_queue[current].id == song.id) return;
    final list = List<Song>.of(_queue);
    final existing = list.indexWhere((s) => s.id == song.id);
    if (existing >= 0) {
      final target = existing < current ? current : current + 1;
      if (existing == target) return;
      list.insert(target, list.removeAt(existing));
      _queue = List.unmodifiable(list);
      await _player.moveAudioSource(existing, target);
    } else {
      list.insert(current + 1, song);
      _queue = List.unmodifiable(list);
      await _player.insertAudioSource(current + 1, _source(song));
    }
    _notify();
  }

  bool _sameQueue(List<Song> songs) {
    if (songs.length != _queue.length) return false;
    for (var i = 0; i < songs.length; i++) {
      if (songs[i].id != _queue[i].id) return false;
    }
    return true;
  }

  int? _relative(int offset) {
    final order = _player.effectiveIndices;
    final current = _player.currentIndex;
    if (order.isEmpty || current == null) return null;
    final at = order.indexOf(current);
    if (at < 0) return null;
    return order[(at + offset) % order.length];
  }

  Future<void> _jump(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final state = _player.processingState;
    if (state == ProcessingState.idle || state == ProcessingState.loading) {
      await _load(index);
      return;
    }
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) unawaited(_player.play());
  }

  Future<void> _load(int index) async {
    final request = ++_request;
    _pendingIndex = index;
    _notify();
    try {
      await _player.setAudioSources(
        _queue.map(_source).toList(),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      if (request != _request) return;
      if (_player.shuffleModeEnabled) await _player.shuffle();
      _pendingIndex = null;
      _notify();
      unawaited(_player.play());
    } on PlayerInterruptedException {
      return;
    } catch (_) {
      if (request != _request) return;
      _pendingIndex = null;
      _fail(index);
    }
  }

  void _fail(int? index) {
    if (_failedRequest == _request) return;
    _failedRequest = _request;
    _pendingIndex = null;
    final failed = index ?? _player.currentIndex;
    final song = failed != null && failed < _queue.length
        ? _queue[failed]
        : null;
    AppMessenger.show(
      song == null
          ? 'Không phát được bài hát'
          : 'Không phát được: ${song.title}',
    );
    _failures++;
    _notify();
    if (failed == null || _queue.length < 2 || _failures > 2) return;
    unawaited(_load((failed + 1) % _queue.length));
  }

  void _onState(PlayerState state) {
    if (state.processingState == ProcessingState.ready) _failures = 0;
    if (state.processingState == ProcessingState.completed && !_rewinding) {
      _rewinding = true;
      unawaited(_rewind());
    }
    _notify();
  }

  Future<void> _rewind() async {
    try {
      await _player.pause();
      final order = _player.effectiveIndices;
      await _player.seek(Duration.zero, index: order.isEmpty ? 0 : order.first);
    } finally {
      _rewinding = false;
    }
  }

  AudioSource _source(Song song) {
    return AudioSource.uri(
      Uri.parse(AudiusApi.streamUrl(song.id)),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: song.durationSeconds > 0 ? song.duration : null,
        artUri: song.artworkLarge.isEmpty ? null : Uri.parse(song.artworkLarge),
      ),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
