import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_messenger.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!_emailPattern.hasMatch(email)) return 'Email không hợp lệ';
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final error = _register
        ? await auth.register(_name.text, _email.text, _password.text)
        : await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      AppMessenger.show(error);
      return;
    }
    Navigator.pop(context);
    AppMessenger.show(
      _register ? 'Tạo tài khoản thành công' : 'Đăng nhập thành công',
    );
  }

  Future<void> _google() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      AppMessenger.show(error);
      return;
    }
    Navigator.pop(context);
    AppMessenger.show('Đăng nhập thành công');
  }

  Future<void> _resetPassword() async {
    final problem = _validateEmail(_email.text);
    if (problem != null) {
      AppMessenger.show('Nhập email hợp lệ để nhận liên kết đặt lại mật khẩu');
      return;
    }
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().resetPassword(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    AppMessenger.show(error ?? 'Đã gửi email đặt lại mật khẩu');
  }

  @override
  Widget build(BuildContext context) {
    final available = context.select<AuthProvider, bool>((a) => a.available);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primary,
                    child: Icon(
                      Icons.headphones_rounded,
                      size: 42,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _register ? 'Tạo tài khoản' : 'Đăng nhập',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lưu bài hát yêu thích, playlist và thống kê theo tài khoản',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (!available)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Firebase chưa được cấu hình nên chưa thể đăng nhập. '
                      'Hãy làm theo file HUONG_DAN_FIREBASE.md rồi chạy lại ứng dụng',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                if (_register) ...[
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Tên cần ít nhất 2 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) < 6
                      ? 'Mật khẩu cần ít nhất 6 ký tự'
                      : null,
                ),
                if (!_register)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy || !available ? null : _resetPassword,
                      child: const Text('Quên mật khẩu'),
                    ),
                  ),
                SizedBox(height: _register ? 24 : 8),
                FilledButton(
                  onPressed: _busy || !available ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_register ? 'Đăng ký' : 'Đăng nhập'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'hoặc',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || !available ? null : _google,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  label: const Text('Tiếp tục với Google'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _register = !_register),
                  child: Text(
                    _register
                        ? 'Đã có tài khoản, đăng nhập ngay'
                        : 'Chưa có tài khoản, đăng ký ngay',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
