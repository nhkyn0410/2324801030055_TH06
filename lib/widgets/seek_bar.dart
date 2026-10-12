import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../utils/formatters.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final scheme = Theme.of(context).colorScheme;
    final total = player.duration;
    final max = math.max(total.inMilliseconds.toDouble(), 1.0);
    final labelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: Colors.white70);

    return StreamBuilder<Duration>(
      stream: player.bufferedStream,
      builder: (context, bufferedSnapshot) {
        final buffered = player.switching
            ? 0.0
            : (bufferedSnapshot.data ?? Duration.zero).inMilliseconds
                  .toDouble()
                  .clamp(0.0, max);
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, snapshot) {
            final position = player.switching
                ? Duration.zero
                : (snapshot.data ?? player.position);
            final value = (_drag ?? position.inMilliseconds.toDouble()).clamp(
              0.0,
              max,
            );
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.white,
                    thumbColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    secondaryActiveTrackColor: Colors.white38,
                    overlayColor: scheme.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    max: max,
                    value: value,
                    secondaryTrackValue: math.max(buffered, value),
                    onChanged: total == Duration.zero
                        ? null
                        : (v) => setState(() => _drag = v),
                    onChangeEnd: (v) {
                      player.seek(Duration(milliseconds: v.round()));
                      setState(() => _drag = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(Duration(milliseconds: value.round())),
                        style: labelStyle,
                      ),
                      Text(formatDuration(total), style: labelStyle),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
