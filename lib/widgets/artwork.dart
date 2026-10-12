import 'package:flutter/material.dart';

class Artwork extends StatelessWidget {
  const Artwork({super.key, required this.url, this.size, this.radius = 8});

  final String url;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: scheme.onSurfaceVariant,
          size: size == null ? 64 : size! * 0.45,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (_, child, frame, sync) {
                  if (sync || frame != null) return child;
                  return placeholder;
                },
              ),
      ),
    );
  }
}
