import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.available}) {
    if (!available) return;
    _user = FirebaseAuth.instance.currentUser;
    _sub = FirebaseAuth.instance.userChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final bool available;
  StreamSubscription<User?>? _sub;
  User? _user;
  bool _googleReady = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String get email => _user?.email ?? '';

  String get displayName {
    final name = _user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final mail = email;
    return mail.contains('@') ? mail.split('@').first : mail;
  }

  Future<String?> signIn(String email, String password) {
    return _run(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<String?> register(String name, String email, String password) {
    return _run(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final user = credential.user;
      if (user == null) return;
      await user.updateDisplayName(name.trim());
      await user.reload();
      _saveProfile(user, name.trim());
    });
  }

  Future<String?> signInWithGoogle() {
    return _run(google: true, () async {
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
      final user = result.user;
      if (user != null && (result.additionalUserInfo?.isNewUser ?? false)) {
        _saveProfile(user, user.displayName ?? account.displayName ?? '');
      }
    });
  }

  Future<String?> resetPassword(String email) {
    return _run(() async {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    });
  }

  Future<void> signOut() async {
    if (!available) return;
    final usedGoogle =
        _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    await FirebaseAuth.instance.signOut();
    if (!usedGoogle) return;
    try {
      await _ensureGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  void _saveProfile(User user, String name) {
    unawaited(
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'displayName': name,
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError((_) {}),
    );
  }

  Future<String?> _run(
    Future<void> Function() action, {
    bool google = false,
  }) async {
    if (!available) return 'Firebase chưa được cấu hình cho ứng dụng';
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code, google: google);
    } on GoogleSignInException catch (e) {
      return _googleMessage(e.code);
    } catch (_) {
      return 'Đã xảy ra lỗi, vui lòng thử lại';
    }
  }

  String _googleMessage(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => 'Đăng nhập Google đã bị hủy. Nếu bạn không tự hủy, hãy kiểm tra SHA-1 trên Firebase Console',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => 'Cấu hình đăng nhập Google chưa đúng, xem lại file HUONG_DAN_FIREBASE.md',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Không mở được cửa sổ đăng nhập Google',
      GoogleSignInExceptionCode.interrupted =>
        'Đăng nhập Google bị gián đoạn, vui lòng thử lại',
      _ => 'Đăng nhập Google thất bại, vui lòng thử lại',
    };
  }

  String _message(String code, {bool google = false}) {
    if (google && code == 'invalid-credential') {
      return 'Cấu hình đăng nhập Google chưa đúng, xem lại file HUONG_DAN_FIREBASE.md';
    }
    switch (code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'weak-password':
        return 'Mật khẩu cần ít nhất 6 ký tự';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần, vui lòng đợi một lát';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trên Firebase Console';
      case 'account-exists-with-different-credential':
        return 'Email này đã đăng ký bằng phương thức đăng nhập khác';
      default:
        return 'Không thực hiện được, mã lỗi $code';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
