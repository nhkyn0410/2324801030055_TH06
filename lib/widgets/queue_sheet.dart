import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../utils/formatters.dart';
import 'artwork.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) => _QueueList(controller: controller),
    ),
  );
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final queue = player.queue;
    final current = player.currentIndex;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách phát', style: text.titleMedium),
                    if (player.queueTitle.isNotEmpty)
                      Text(
                        player.queueTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${queue.length} bài hát',
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final song = queue[index];
              final selected = index == current;
              return ListTile(
                selected: selected,
                selectedTileColor: scheme.primary.withValues(alpha: 0.12),
                leading: Artwork(url: song.artworkSmall, size: 46, radius: 6),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: selected
                    ? Icon(
                        player.playing
                            ? Icons.graphic_eq_rounded
                            : Icons.pause_rounded,
                        color: scheme.primary,
                      )
                    : Text(
                        formatDuration(song.duration),
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                onTap: () => player.playAt(index),
              );
            },
          ),
        ),
      ],
    );
  }
}
