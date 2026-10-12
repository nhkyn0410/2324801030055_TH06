import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/app_messenger.dart';
import '../utils/formatters.dart';
import '../widgets/login_prompt.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<StatsProvider>().flush();
    await context.read<AuthProvider>().signOut();
    AppMessenger.show('Đã đăng xuất');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return SafeArea(
        child: LoginPrompt(
          icon: Icons.person_rounded,
          title: 'Tài khoản',
          message: auth.available
              ? 'Đăng nhập để đồng bộ bài hát đã thích, playlist và thống kê trên mọi thiết bị'
              : 'Firebase chưa được cấu hình. Hãy làm theo file HUONG_DAN_FIREBASE.md rồi chạy lại ứng dụng',
        ),
      );
    }

    final library = context.watch<LibraryProvider>();
    final stats = context.watch<StatsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = auth.displayName;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: scheme.primary,
              child: Text(
                name.isEmpty ? 'U' : name.characters.first.toUpperCase(),
                style: text.headlineLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            auth.email,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.favorite_rounded,
                  label: 'Bài hát đã thích',
                  value: '${library.liked.length}',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.queue_music_rounded,
                  label: 'Playlist',
                  value: '${library.playlists.length}',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Thời gian đã nghe',
                  value: formatListening(stats.totalSeconds),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
