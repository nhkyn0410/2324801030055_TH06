import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../utils/app_messenger.dart';
import '../widgets/artwork.dart';
import '../widgets/library_actions.dart';
import '../widgets/login_prompt.dart';
import 'collection_screen.dart';

enum _PlaylistAction { rename, delete }

Future<void> renamePlaylist(BuildContext context, Playlist playlist) async {
  final name = await askPlaylistName(
    context,
    title: 'Đổi tên playlist',
    initial: playlist.name,
  );
  if (name == null || !context.mounted) return;
  context.read<LibraryProvider>().renamePlaylist(playlist.id, name);
}

Future<bool> confirmDeletePlaylist(
  BuildContext context,
  Playlist playlist,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa playlist'),
      content: Text('Bạn có chắc muốn xóa playlist ${playlist.name} không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  context.read<LibraryProvider>().deletePlaylist(playlist.id);
  AppMessenger.show('Đã xóa playlist ${playlist.name}');
  return true;
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void _open(BuildContext context, String? playlistId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionScreen(playlistId: playlistId),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = await askPlaylistName(context);
    if (name == null || !context.mounted) return;
    context.read<LibraryProvider>().createPlaylist(name);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    if (!loggedIn) {
      return const SafeArea(
        child: LoginPrompt(
          icon: Icons.library_music_rounded,
          title: 'Thư viện của bạn',
          message: 'Đăng nhập để lưu bài hát yêu thích và tạo playlist cho riêng mình',
        ),
      );
    }

    final library = context.watch<LibraryProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Thư viện',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(context, null),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bài hát đã thích',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${library.liked.length} bài hát',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Playlist của tôi',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo mới'),
                ),
              ],
            ),
          ),
          if (library.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Chưa có playlist nào. Nhấn Tạo mới để bắt đầu',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final playlist in library.playlists)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 4),
              leading: playlist.songs.isEmpty
                  ? const Artwork(url: '', size: 52)
                  : Artwork(url: playlist.songs.first.artworkSmall, size: 52),
              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${playlist.songs.length} bài hát'),
              trailing: PopupMenuButton<_PlaylistAction>(
                tooltip: 'Tùy chọn',
                onSelected: (action) {
                  switch (action) {
                    case _PlaylistAction.rename:
                      renamePlaylist(context, playlist);
                    case _PlaylistAction.delete:
                      confirmDeletePlaylist(context, playlist);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _PlaylistAction.rename,
                    child: Text('Đổi tên'),
                  ),
                  PopupMenuItem(
                    value: _PlaylistAction.delete,
                    child: Text('Xóa playlist'),
                  ),
                ],
              ),
              onTap: () => _open(context, playlist.id),
            ),
        ],
      ),
    );
  }
}
