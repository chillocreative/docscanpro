import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/features/library/data/library_providers.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/library/presentation/library_page.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets(
    'library page shows the My Documents header and empty-state message',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LibraryPage(),
          overrides: [
            documentsProvider.overrideWith(
              (ref) async => <DocumentEntity>[],
            ),
            // Pretend the user is paid so the BannerAdView short-circuits
            // and we don't reach into google_mobile_ads.
            adsHiddenProvider.overrideWith((ref) => true),
          ],
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(find.text(S.myDocuments), findsOneWidget);
      expect(find.textContaining('No documents yet'), findsOneWidget);
      expect(find.text(S.searchDocumentsHint), findsOneWidget);
    },
  );
}
