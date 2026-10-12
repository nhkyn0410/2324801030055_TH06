import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/player_provider.dart';
import '../services/audius_api.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final name = context.select<AuthProvider, String>(
      (a) => a.isLoggedIn ? a.displayName : '',
    );
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Khám phá âm nhạc' : 'Xin chào, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nghe nhạc trực tuyến, không cần tải về',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    catalog.setQuery(value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm bài hát, nghệ sĩ',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              catalog.setQuery('');
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (!catalog.searching)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final genre in ['', ...AudiusApi.genres])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(genre.isEmpty ? 'Tất cả' : genre),
                        selected: catalog.genre == genre,
                        showCheckmark: false,
                        onSelected: (_) => catalog.setGenre(genre),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    catalog.title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (catalog.songs.isNotEmpty)
                  Text(
                    '${catalog.songs.length} bài hát',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 2,
            child: catalog.loading && catalog.songs.isNotEmpty
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
          Expanded(child: _SongList(catalog: catalog)),
        ],
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({required this.catalog});

  final CatalogProvider catalog;

  @override
  Widget build(BuildContext context) {
    final songs = catalog.songs;
    final scheme = Theme.of(context).colorScheme;

    if (songs.isEmpty) {
      if (catalog.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      final error = catalog.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                error == null
                    ? Icons.search_off_rounded
                    : Icons.cloud_off_rounded,
                size: 56,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                error ?? 'Không tìm thấy bài hát phù hợp',
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: catalog.load,
                  child: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.load,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongTile(
            key: ValueKey(song.id),
            song: song,
            onTap: () {
              FocusScope.of(context).unfocus();
              context.read<PlayerProvider>().playSongs(
                songs,
                index,
                title: catalog.title,
              );
              openPlayerScreen(context);
            },
          );
        },
      ),
    );
  }
}
