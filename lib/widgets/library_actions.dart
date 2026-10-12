import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/auth_screen.dart';
import '../utils/app_messenger.dart';

void openAuthScreen() {
  AppMessenger.navigator.currentState?.push(
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );
}

bool ensureLoggedIn(BuildContext context) {
  if (context.read<AuthProvider>().isLoggedIn) return true;
  AppMessenger.show(
    'Đăng nhập để dùng tính năng này',
    action: const SnackBarAction(label: 'Đăng nhập', onPressed: openAuthScreen),
  );
  return false;
}

void toggleLike(BuildContext context, Song song) {
  if (!ensureLoggedIn(context)) return;
  context.read<LibraryProvider>().toggleLike(song);
}

Future<void> showAddToPlaylist(BuildContext context, Song song) async {
  if (!ensureLoggedIn(context)) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddToPlaylistSheet(song: song),
  );
}

Future<String?> askPlaylistName(
  BuildContext context, {
  String title = 'Tạo playlist mới',
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, initial: initial),
  );
}

class _AddToPlaylistSheet extends StatelessWidget {
  const _AddToPlaylistSheet({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Thêm vào playlist',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.add, color: scheme.onPrimaryContainer),
              ),
              title: const Text('Tạo playlist mới'),
              onTap: () async {
                final name = await askPlaylistName(context);
                if (name == null || !context.mounted) return;
                library.createPlaylist(name, firstSong: song);
                Navigator.pop(context);
                AppMessenger.show('Đã tạo playlist $name');
              },
            ),
            for (final playlist in library.playlists)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: const Icon(Icons.queue_music_rounded),
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${playlist.songs.length} bài hát'),
                trailing: playlist.contains(song.id)
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  final added = library.addToPlaylist(playlist.id, song);
                  Navigator.pop(context);
                  AppMessenger.show(
                    added
                        ? 'Đã thêm vào ${playlist.name}'
                        : 'Bài hát đã có trong ${playlist.name}',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Tên playlist'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
