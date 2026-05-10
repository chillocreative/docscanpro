import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Library list/grid toggle. Default = list, matches the screenshot.
final libraryIsListProvider = StateProvider<bool>((_) => true);

/// Free-text search filter applied to document titles.
final libraryQueryProvider = StateProvider<String>((_) => '');
