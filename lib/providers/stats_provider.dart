import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/play_stat.dart';
import '../models/song.dart';
import '../utils/formatters.dart';
import 'player_provider.dart';

class StatsProvider extends ChangeNotifier {
  StatsProvider({required this.available, required this.player}) {
    if (!available) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) => _bind(user?.uid),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const _playThreshold = 10;
  static const _flushEvery = 20;

  final bool available;
  final PlayerProvider player;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _playsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dailySub;
  Timer? _ticker;

  String? _uid;
  List<PlayStat> _plays = const [];
  Map<String, int> _daily = const {};

  Song? _tracked;
  int _sessionSeconds = 0;
  int _pendingSeconds = 0;
  int _pendingPlays = 0;
  bool _counted = false;

  bool get isEmpty => _plays.isEmpty;
  int get totalSeconds => _plays.fold(0, (total, p) => total + p.seconds);
  int get totalPlays => _plays.fold(0, (total, p) => total + p.count);
  int get songCount => _plays.length;
  int get artistCount => _plays.map((p) => p.song.artist).toSet().length;

  List<PlayStat> get recent => _plays.take(10).toList();

  List<PlayStat> get topSongs {
    final sorted = List<PlayStat>.of(_plays)
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : b.seconds.compareTo(a.seconds);
      });
    return sorted.where((p) => p.count > 0).take(5).toList();
  }

  List<ArtistStat> get topArtists {
    final grouped = <String, ArtistStat>{};
    for (final play in _plays) {
      final name = play.song.artist;
      final current = grouped[name];
      grouped[name] = ArtistStat(
        name: name,
        artwork: current?.artwork ?? play.song.artworkSmall,
        count: (current?.count ?? 0) + play.count,
        seconds: (current?.seconds ?? 0) + play.seconds,
      );
    }
    final sorted = grouped.values.toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));
    return sorted.take(5).toList();
  }

  List<DayStat> get lastWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return DayStat(day: day, seconds: _daily[dayKey(day)] ?? 0);
    });
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  void _bind(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _playsSub?.cancel();
    _dailySub?.cancel();
    _plays = const [];
    _daily = const {};
    _tracked = null;
    _resetPending();
    notifyListeners();
    if (uid == null) return;

    _playsSub = _userDoc(uid)
        .collection('plays')
        .orderBy('lastPlayedAt', descending: true)
        .limit(300)
        .snapshots()
        .listen((snapshot) {
          _plays = snapshot.docs.map((d) => _parse(d.data())).toList();
          notifyListeners();
        }, onError: (_) {});

    final start = dayKey(DateTime.now().subtract(const Duration(days: 6)));
    _dailySub = _userDoc(uid)
        .collection('daily')
        .where('date', isGreaterThanOrEqualTo: start)
        .snapshots()
        .listen((snapshot) {
          _daily = {
            for (final d in snapshot.docs)
              d.id: (d.data()['seconds'] as num?)?.toInt() ?? 0,
          };
          notifyListeners();
        }, onError: (_) {});
  }

  PlayStat _parse(Map<String, dynamic> data) {
    final song = data['song'];
    final time = data['lastPlayedAt'];
    return PlayStat(
      song: Song.fromMap(
        song is Map ? Map<String, dynamic>.from(song) : const {},
      ),
      count: (data['count'] as num?)?.toInt() ?? 0,
      seconds: (data['seconds'] as num?)?.toInt() ?? 0,
      lastPlayedAt: time is Timestamp ? time.toDate() : DateTime.now(),
    );
  }

  void _tick() {
    if (_uid == null) return;
    final song = player.currentSong;
    if (song == null || !player.audible) {
      if (_pendingSeconds > 0) flush();
      return;
    }
    if (_tracked?.id != song.id) {
      flush();
      _tracked = song;
      _sessionSeconds = 0;
      _counted = false;
    }
    _sessionSeconds++;
    _pendingSeconds++;
    if (!_counted && _sessionSeconds >= _playThreshold) {
      _counted = true;
      _pendingPlays++;
    }
    if (_pendingSeconds >= _flushEvery) flush();
  }

  void flush() {
    final uid = _uid;
    final song = _tracked;
    if (uid == null || song == null) return;
    if (_pendingSeconds == 0 && _pendingPlays == 0) return;
    final seconds = _pendingSeconds;
    final plays = _pendingPlays;
    _resetPending();

    final today = dayKey(DateTime.now());
    final batch = FirebaseFirestore.instance.batch()
      ..set(_userDoc(uid).collection('plays').doc(song.id), {
        'song': song.toMap(),
        'seconds': FieldValue.increment(seconds),
        'count': FieldValue.increment(plays),
        'lastPlayedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      ..set(_userDoc(uid).collection('daily').doc(today), {
        'date': today,
        'seconds': FieldValue.increment(seconds),
        'plays': FieldValue.increment(plays),
      }, SetOptions(merge: true));
    unawaited(batch.commit().catchError((_) {}));
  }

  void _resetPending() {
    _pendingSeconds = 0;
    _pendingPlays = 0;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _authSub?.cancel();
    _playsSub?.cancel();
    _dailySub?.cancel();
    super.dispose();
  }
}
