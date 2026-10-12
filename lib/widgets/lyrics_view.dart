import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lyrics.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_service.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.song});

  final Song song;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late Future<Lyrics?> _future = _fetch();

  Future<Lyrics?> _fetch() {
    return context.read<LyricsService>().fetch(widget.song);
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _future = _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lyrics?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.cloud_off_rounded,
            text: 'Không tải được lời bài hát',
            action: TextButton(
              onPressed: () => setState(() => _future = _fetch()),
              child: const Text('Thử lại'),
            ),
          );
        }
        final lyrics = snapshot.data;
        if (lyrics == null || lyrics.lines.isEmpty) {
          return const _Message(
            icon: Icons.lyrics_outlined,
            text: 'Chưa có lời cho bài hát này',
          );
        }
        if (!lyrics.synced) return _PlainLyrics(lyrics: lyrics);
        return _SyncedLyrics(key: ValueKey(widget.song.id), lyrics: lyrics);
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white54),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.white70)),
          ?action,
        ],
      ),
    );
  }
}

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.lyrics});

  final Lyrics lyrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lời bài hát chưa có mốc thời gian',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            lyrics.lines.map((l) => l.text).join('\n'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncedLyrics extends StatefulWidget {
  const _SyncedLyrics({super.key, required this.lyrics});

  final Lyrics lyrics;

  @override
  State<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends State<_SyncedLyrics> {
  static const _lead = Duration(milliseconds: 250);

  late final List<GlobalKey> _keys = List.generate(
    widget.lyrics.lines.length,
    (_) => GlobalKey(),
  );
  late final PlayerProvider _player = context.read<PlayerProvider>();
  StreamSubscription<Duration>? _sub;
  int _active = -1;

  @override
  void initState() {
    super.initState();
    _sub = _player.positionStream.listen(_onPosition);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onPosition(Duration position) {
    final index = _player.switching
        ? -1
        : widget.lyrics.indexAt(position + _lead);
    if (index == _active || !mounted) return;
    setState(() => _active = index);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[index].currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.35,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lyrics.lines;
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, 0.08, 0.92, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines.length; i++)
              InkWell(
                key: _keys[i],
                borderRadius: BorderRadius.circular(8),
                onTap: () => _player.seek(lines[i].time),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: i == _active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.38),
                    ),
                    child: Text(lines[i].text.isEmpty ? ' ' : lines[i].text),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
