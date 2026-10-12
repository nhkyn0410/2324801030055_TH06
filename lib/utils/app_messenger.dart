import 'package:flutter/material.dart';

class AppMessenger {
  static final key = GlobalKey<ScaffoldMessengerState>();
  static final navigator = GlobalKey<NavigatorState>();

  static void show(String message, {SnackBarAction? action}) {
    final state = key.currentState;
    if (state == null) return;
    state
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
