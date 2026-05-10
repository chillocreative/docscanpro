import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global theme-mode provider. Settings screen mutates this; persistence is
/// added in M12 once `shared_preferences` is on the dep list.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
