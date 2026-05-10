import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Lightweight logger wrapper. Replaces direct `print` calls so the
/// `avoid_print` lint can stay strict.
class Logger {
  const Logger(this.tag);
  final String tag;

  void d(String message) => _log('D', message);
  void i(String message) => _log('I', message);
  void w(String message) => _log('W', message);
  void e(String message, [Object? error, StackTrace? stack]) {
    _log('E', message);
    if (error != null) dev.log('$tag/E error', error: error, stackTrace: stack);
  }

  void _log(String level, String message) {
    if (!kDebugMode) return;
    dev.log('[$level] $message', name: tag);
  }
}
