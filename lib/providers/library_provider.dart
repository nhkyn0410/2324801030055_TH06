import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../utils/app_messenger.dart';

class LibraryProvider extends ChangeNotifier {
  LibraryProvider({required this.available}) {
    if (!available) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) => _bind(user?.uid),
    );
  }

  final bool available;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _likesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _playlistsSub;

  String? _uid;
  List<Song> _liked = const [];
  Set<String> _likedIds = const {};
  List<Playlist> _playlists = const [];

  List<Song> get liked => _liked;
  List<Playlist> get playlists => _playlists;

  bool isLiked(String songId) => _likedIds.contains(songId);

  Playlist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  void _bind(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _likesSub?.cancel();
    _playlistsSub?.cancel();
    _liked = const [];
    _likedIds = const {};
    _playlists = const [];
    notifyListeners();
    if (uid == null) return;

    _likesSub = _userDoc
        .collection('likes')
        .orderBy('likedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _liked = snapshot.docs.map((d) => Song.fromMap(d.data())).toList();
          _likedIds = _liked.map((s) => s.id).toSet();
          notifyListeners();
        }, onError: _onError);

    _playlistsSub = _userDoc
        .collection('playlists')
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          _playlists = snapshot.docs
              .map((d) => Playlist.fromMap(d.id, d.data()))
              .toList();
          notifyListeners();
        }, onError: _onError);
  }

  void toggleLike(Song song) {
    if (_uid == null) return;
    final ref = _userDoc.collection('likes').doc(song.id);
    if (isLiked(song.id)) {
      _write(ref.delete());
    } else {
      _write(
        ref.set({...song.toMap(), 'likedAt': FieldValue.serverTimestamp()}),
      );
    }
  }

  void createPlaylist(String name, {Song? firstSong}) {
    if (_uid == null) return;
    _write(
      _userDoc.collection('playlists').doc().set({
        'name': name.trim(),
        'songs': [if (firstSong != null) firstSong.toMap()],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  void renamePlaylist(String id, String name) {
    if (_uid == null) return;
    _write(
      _userDoc.collection('playlists').doc(id).update({
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  void deletePlaylist(String id) {
    if (_uid == null) return;
    _write(_userDoc.collection('playlists').doc(id).delete());
  }

  bool addToPlaylist(String id, Song song) {
    final playlist = playlistById(id);
    if (_uid == null || playlist == null || playlist.contains(song.id)) {
      return false;
    }
    _saveSongs(id, [...playlist.songs, song]);
    return true;
  }

  void removeFromPlaylist(String id, Song song) {
    final playlist = playlistById(id);
    if (_uid == null || playlist == null) return;
    _saveSongs(id, playlist.songs.where((s) => s.id != song.id).toList());
  }

  void _saveSongs(String id, List<Song> songs) {
    _write(
      _userDoc.collection('playlists').doc(id).update({
        'songs': songs.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  void _write(Future<void> future) {
    unawaited(future.catchError(_onError));
  }

  void _onError(Object error) {
    final denied =
        error is FirebaseException && error.code == 'permission-denied';
    AppMessenger.show(
      denied
          ? 'Firestore từ chối truy cập, hãy kiểm tra lại Rules'
          : 'Không đồng bộ được dữ liệu với Firestore',
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _likesSub?.cancel();
    _playlistsSub?.cancel();
    super.dispose();
  }
}
