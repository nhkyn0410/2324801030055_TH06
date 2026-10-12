import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/artwork.dart';
import '../widgets/library_actions.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/seek_bar.dart';

void openPlayerScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const PlayerScreen(),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Chưa có bài hát nào đang phát')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(url: song.artworkLarge),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _TopBar(song: song, source: player.queueTitle),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showLyrics
                          ? LyricsView(
                              key: const ValueKey('lyrics'),
                              song: song,
                            )
                          : _Cover(
                              key: const ValueKey('cover'),
                              url: song.artworkLarge,
                              playing: player.playing,
                            ),
                    ),
                  ),
                  _SongHeader(song: song),
                  const SizedBox(height: 8),
                  const SeekBar(),
                  const SizedBox(height: 4),
                  _Controls(player: player),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: _showLyrics
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white70,
                        ),
                        icon: const Icon(Icons.lyrics_outlined),
                        label: const Text('Lời bài hát'),
                        onPressed: () =>
                            setState(() => _showLyrics = !_showLyrics),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        icon: const Icon(Icons.queue_music_rounded),
                        label: const Text('Danh sách phát'),
                        onPressed: () => showQueueSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: ImageFiltered(
              key: ValueKey(url),
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xE6000000)],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.song, required this.source});

  final Song song;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Thu nhỏ',
          color: Colors.white,
          iconSize: 30,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'ĐANG PHÁT TỪ',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                source.isEmpty ? 'Hàng chờ' : source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Thêm vào playlist',
          color: Colors.white,
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () => showAddToPlaylist(context, song),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({super.key, required this.url, required this.playing});

  final String url;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight) - 32;
        return Center(
          child: AnimatedScale(
            scale: playing ? 1 : 0.9,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Artwork(url: url, size: math.max(side, 80), radius: 20),
            ),
          ),
        );
      },
    );
  }
}

class _SongHeader extends StatelessWidget {
  const _SongHeader({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final liked = context.select<LibraryProvider, bool>(
      (l) => l.isLiked(song.id),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: liked ? 'Bỏ thích' : 'Thích',
            iconSize: 28,
            color: liked ? Theme.of(context).colorScheme.primary : Colors.white,
            icon: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            onPressed: () => toggleLike(context, song),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});

  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final busy = player.switching || (player.loading && player.playing);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Phát ngẫu nhiên',
          color: player.shuffle ? primary : Colors.white70,
          icon: const Icon(Icons.shuffle_rounded),
          onPressed: player.toggleShuffle,
        ),
        IconButton(
          tooltip: 'Bài trước',
          color: Colors.white,
          iconSize: 42,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: player.previous,
        ),
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IconButton.filled(
                tooltip: player.playing ? 'Tạm dừng' : 'Phát',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                iconSize: 40,
                icon: Icon(
                  player.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: player.toggle,
              ),
              if (busy)
                IgnorePointer(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: primary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Bài tiếp',
          color: Colors.white,
          iconSize: 42,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: player.next,
        ),
        IconButton(
          tooltip: switch (player.loopMode) {
            LoopMode.off => 'Lặp lại: tắt',
            LoopMode.all => 'Lặp lại danh sách',
            LoopMode.one => 'Lặp lại một bài',
          },
          color: player.loopMode == LoopMode.off ? Colors.white70 : primary,
          icon: Icon(
            player.loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
          ),
          onPressed: player.cycleLoopMode,
        ),
      ],
    );
  }
}
