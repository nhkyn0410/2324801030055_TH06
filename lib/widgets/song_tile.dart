import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../utils/app_messenger.dart';
import '../utils/formatters.dart';
import 'artwork.dart';
import 'library_actions.dart';

enum _SongAction { playNext, addToPlaylist, remove }

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onRemove,
    this.removeLabel = 'Xóa khỏi playlist',
    this.caption,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String removeLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isCurrent = context.select<PlayerProvider, bool>(
      (p) => p.currentSong?.id == song.id,
    );
    final isActive = context.select<PlayerProvider, bool>(
      (p) => p.currentSong?.id == song.id && p.playing,
    );
    final liked = context.select<LibraryProvider, bool>(
      (l) => l.isLiked(song.id),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Artwork(url: song.artworkSmall, size: 54),
                if (isCurrent)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isActive ? Icons.graphic_eq_rounded : Icons.pause_rounded,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? scheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              caption ?? formatDuration(song.duration),
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            IconButton(
              tooltip: liked ? 'Bỏ thích' : 'Thích',
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? scheme.primary : scheme.onSurfaceVariant,
              ),
              onPressed: () => toggleLike(context, song),
            ),
            PopupMenuButton<_SongAction>(
              tooltip: 'Tùy chọn',
              icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              onSelected: (action) => _onAction(context, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _SongAction.playNext,
                  child: Text('Phát tiếp theo'),
                ),
                const PopupMenuItem(
                  value: _SongAction.addToPlaylist,
                  child: Text('Thêm vào playlist'),
                ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: _SongAction.remove,
                    child: Text(removeLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAction(BuildContext context, _SongAction action) {
    switch (action) {
      case _SongAction.playNext:
        context.read<PlayerProvider>().playNext(song);
        AppMessenger.show('Sẽ phát tiếp theo: ${song.title}');
      case _SongAction.addToPlaylist:
        showAddToPlaylist(context, song);
      case _SongAction.remove:
        onRemove?.call();
    }
  }
}
