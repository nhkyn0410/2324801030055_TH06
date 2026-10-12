import 'song.dart';

class PlayStat {
  const PlayStat({
    required this.song,
    required this.count,
    required this.seconds,
    required this.lastPlayedAt,
  });

  final Song song;
  final int count;
  final int seconds;
  final DateTime lastPlayedAt;
}

class ArtistStat {
  const ArtistStat({
    required this.name,
    required this.artwork,
    required this.count,
    required this.seconds,
  });

  final String name;
  final String artwork;
  final int count;
  final int seconds;
}

class DayStat {
  const DayStat({required this.day, required this.seconds});

  final DateTime day;
  final int seconds;
}
