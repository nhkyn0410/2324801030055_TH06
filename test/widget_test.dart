import 'package:flutter_test/flutter_test.dart';
import 'package:th06_2324801030055/models/lyrics.dart';
import 'package:th06_2324801030055/models/song.dart';
import 'package:th06_2324801030055/services/lyrics_service.dart';
import 'package:th06_2324801030055/utils/formatters.dart';

void main() {
  test('Lyrics.fromLrc parses and sorts timestamps', () {
    final lyrics = Lyrics.fromLrc(
      '[00:12.50]Second line\n[00:01.00]First line\n[01:02.345]Third line\nno tag',
    );
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.map((l) => l.text), [
      'First line',
      'Second line',
      'Third line',
    ]);
    expect(
      lyrics.lines[1].time,
      const Duration(seconds: 12, milliseconds: 500),
    );
    expect(
      lyrics.lines[2].time,
      const Duration(minutes: 1, seconds: 2, milliseconds: 345),
    );
  });

  test('Lyrics.indexAt returns the active line', () {
    final lyrics = Lyrics.fromLrc('[00:01.00]A\n[00:05.00]B\n[00:09.00]C');
    expect(lyrics.indexAt(Duration.zero), -1);
    expect(lyrics.indexAt(const Duration(seconds: 1)), 0);
    expect(lyrics.indexAt(const Duration(seconds: 6)), 1);
    expect(lyrics.indexAt(const Duration(minutes: 3)), 2);
  });

  test('LyricsService.cleanQuery strips labels and splits artist', () {
    expect(
      LyricsService.cleanQuery(
        'Rowsfred - CLAWN (Original Mix) [Eclipse Records]',
        'ROWSFRED',
      ),
      ('CLAWN', 'ROWSFRED'),
    );
    expect(LyricsService.cleanQuery('G Mills - Terracotta', 'Chillhop Music'), (
      'Terracotta',
      'G Mills',
    ));
    expect(
      LyricsService.cleanQuery('Lost My Mind ft. William Bolton', 'inverness'),
      ('Lost My Mind', 'inverness'),
    );
  });

  test('Song.fromAudius maps fields and filters unplayable tracks', () {
    final json = {
      'id': 'abc',
      'title': ' Hello ',
      'duration': 125,
      'genre': 'Pop',
      'is_streamable': true,
      'is_stream_gated': false,
      'access': {'stream': true},
      'artwork': {'150x150': 'small.jpg', '480x480': 'large.jpg'},
      'user': {'name': 'Artist'},
    };
    final song = Song.fromAudius(json);
    expect(Song.isPlayable(json), isTrue);
    expect(song.title, 'Hello');
    expect(song.artist, 'Artist');
    expect(song.artworkLarge, 'large.jpg');
    expect(Song.fromMap(song.toMap()).durationSeconds, 125);
    expect(Song.isPlayable({...json, 'is_streamable': false}), isFalse);
    expect(Song.isPlayable({...json, 'is_stream_gated': true}), isFalse);
  });

  test('formatters', () {
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
    expect(formatDuration(const Duration(seconds: 3725)), '1:02:05');
    expect(formatListening(45), '45 giây');
    expect(formatListening(8100), '2 giờ 15 phút');
    expect(dayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
