import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/play_stat.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/formatters.dart';
import '../widgets/artwork.dart';
import '../widgets/login_prompt.dart';
import '../widgets/song_tile.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    if (!loggedIn) {
      return const SafeArea(
        child: LoginPrompt(
          icon: Icons.insights_rounded,
          title: 'Thống kê nghe nhạc',
          message: 'Đăng nhập để theo dõi thời gian nghe, bài hát và nghệ sĩ bạn nghe nhiều nhất',
        ),
      );
    }

    final stats = context.watch<StatsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final recent = stats.recent;
    final topSongs = stats.topSongs;
    final topArtists = stats.topArtists;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Thống kê nghe nhạc',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _SummaryCard(
                      icon: Icons.schedule_rounded,
                      label: 'Thời gian nghe',
                      value: formatListening(stats.totalSeconds),
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Lượt phát',
                      value: '${stats.totalPlays}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryCard(
                      icon: Icons.music_note_rounded,
                      label: 'Bài hát đã nghe',
                      value: '${stats.songCount}',
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: Icons.person_rounded,
                      label: 'Nghệ sĩ',
                      value: '${stats.artistCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _SectionTitle('7 ngày gần đây'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _WeekChart(days: stats.lastWeek),
          ),
          if (stats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Chưa có dữ liệu. Hãy nghe vài bài hát để bắt đầu thống kê',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (topSongs.isNotEmpty) ...[
            const _SectionTitle('Bài hát nghe nhiều nhất'),
            for (var i = 0; i < topSongs.length; i++)
              _RankRow(
                rank: i + 1,
                artwork: topSongs[i].song.artworkSmall,
                title: topSongs[i].song.title,
                subtitle: topSongs[i].song.artist,
                value: '${topSongs[i].count} lượt',
              ),
          ],
          if (topArtists.isNotEmpty) ...[
            const _SectionTitle('Nghệ sĩ nghe nhiều nhất'),
            for (var i = 0; i < topArtists.length; i++)
              _RankRow(
                rank: i + 1,
                artwork: topArtists[i].artwork,
                title: topArtists[i].name,
                subtitle: '${topArtists[i].count} lượt phát',
                value: formatListening(topArtists[i].seconds),
                round: true,
              ),
          ],
          if (recent.isNotEmpty) ...[
            const _SectionTitle('Nghe gần đây'),
            for (var i = 0; i < recent.length; i++)
              SongTile(
                key: ValueKey(recent[i].song.id),
                song: recent[i].song,
                onTap: () => context.read<PlayerProvider>().playSongs(
                  recent.map((p) => p.song).toList(),
                  i,
                  title: 'Nghe gần đây',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<DayStat> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final peak = days.fold(0, (value, d) => math.max(value, d.seconds));
    const barHeight = 96.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${(days[i].seconds / 60).round()}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: barHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: 18,
                        height: peak == 0
                            ? 4
                            : math.max(4, barHeight * days[i].seconds / peak),
                        decoration: BoxDecoration(
                          color: i == days.length - 1
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekdayLabel(days[i].day),
                    style: text.labelMedium?.copyWith(
                      fontWeight: i == days.length - 1
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.artwork,
    required this.title,
    required this.subtitle,
    required this.value,
    this.round = false,
  });

  final int rank;
  final String artwork;
  final String title;
  final String subtitle;
  final String value;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: rank == 1 ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          Artwork(url: artwork, size: 46, radius: round ? 23 : 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
