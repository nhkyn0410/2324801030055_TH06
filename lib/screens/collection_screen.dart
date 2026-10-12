import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/artwork.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';
import 'library_screen.dart';
import 'player_screen.dart';

enum _MenuAction { rename, delete }

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, this.playlistId});

  final String? playlistId;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final id = playlistId;
    final playlist = id == null ? null : library.playlistById(id);

    if (id != null && playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Playlist này không còn tồn tại')),
      );
    }

    final songs = playlist?.songs ?? library.liked;
    final name = playlist?.name ?? 'Bài hát đã thích';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    void play(int index, {bool? shuffle}) {
      context.read<PlayerProvider>().playSongs(
        songs,
        index,
        title: name,
        shuffle: shuffle,
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (playlist != null)
            PopupMenuButton<_MenuAction>(
              tooltip: 'Tùy chọn',
              onSelected: (action) async {
                switch (action) {
                  case _MenuAction.rename:
                    await renamePlaylist(context, playlist);
                  case _MenuAction.delete:
                    final deleted = await confirmDeletePlaylist(
                      context,
                      playlist,
                    );
                    if (deleted && context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.rename,
                  child: Text('Đổi tên'),
                ),
                PopupMenuItem(
                  value: _MenuAction.delete,
                  child: Text('Xóa playlist'),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _Cover(songs: songs, liked: playlist == null),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} bài hát',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            play(0, shuffle: false);
                            openPlayerScreen(context);
                          },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Phát tất cả'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: songs.isEmpty
                        ? null
                        : () {
                            play(Random().nextInt(songs.length), shuffle: true);
                            openPlayerScreen(context);
                          },
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Trộn bài'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (songs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                playlist == null
                    ? 'Nhấn biểu tượng trái tim ở bài hát để lưu vào đây'
                    : 'Playlist chưa có bài hát nào. Mở menu của bài hát và chọn Thêm vào playlist',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (var i = 0; i < songs.length; i++)
            SongTile(
              key: ValueKey(songs[i].id),
              song: songs[i],
              onTap: () {
                play(i);
                openPlayerScreen(context);
              },
              onRemove: playlist == null
                  ? null
                  : () => library.removeFromPlaylist(playlist.id, songs[i]),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.songs, required this.liked});

  final List<Song> songs;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 104.0;
    if (liked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.tertiary],
          ),
        ),
        child: Icon(Icons.favorite_rounded, size: 48, color: scheme.onPrimary),
      );
    }
    final covers = songs
        .map((s) => s.artworkSmall)
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();
    if (covers.length < 4) {
      return Artwork(
        url: covers.isEmpty ? '' : covers.first,
        size: size,
        radius: 16,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [for (final url in covers) Artwork(url: url, radius: 0)],
        ),
      ),
    );
  }
}
