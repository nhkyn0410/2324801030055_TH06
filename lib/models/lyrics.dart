class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

class Lyrics {
  const Lyrics({required this.lines, required this.synced});

  final List<LyricLine> lines;
  final bool synced;

  static final _tag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

  factory Lyrics.fromLrc(String raw) {
    final lines = <LyricLine>[];
    for (final row in raw.split('\n')) {
      final matches = _tag.allMatches(row).toList();
      if (matches.isEmpty) continue;
      final text = row.substring(matches.last.end).trim();
      for (final m in matches) {
        final fraction = (m.group(3) ?? '0').padRight(3, '0');
        lines.add(
          LyricLine(
            Duration(
              minutes: int.parse(m.group(1)!),
              seconds: int.parse(m.group(2)!),
              milliseconds: int.parse(fraction),
            ),
            text,
          ),
        );
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return Lyrics(lines: lines, synced: true);
  }

  factory Lyrics.fromPlain(String raw) {
    return Lyrics(
      lines: raw
          .split('\n')
          .map((row) => LyricLine(Duration.zero, row.trim()))
          .toList(),
      synced: false,
    );
  }

  int indexAt(Duration position) {
    if (!synced || lines.isEmpty) return -1;
    var low = 0;
    var high = lines.length - 1;
    var result = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lines[mid].time <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }
}
