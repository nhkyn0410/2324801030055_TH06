import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import 'artwork.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => openPlayerScreen(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final total = player.duration.inMilliseconds;
                final current = player.switching
                    ? 0
                    : (snapshot.data ?? Duration.zero).inMilliseconds;
                return LinearProgressIndicator(
                  value: total <= 0 ? 0 : (current / total).clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: scheme.surfaceContainerHighest,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Artwork(url: song.artworkSmall, size: 44, radius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bài trước',
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: player.previous,
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: player.loading && player.playing || player.switching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : IconButton(
                            tooltip: player.playing ? 'Tạm dừng' : 'Phát',
                            iconSize: 30,
                            icon: Icon(
                              player.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            onPressed: player.toggle,
                          ),
                  ),
                  IconButton(
                    tooltip: 'Bài tiếp',
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: player.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
