import 'dart:io';

import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/features/export/data/export_service.dart';
import 'package:doc_scan_ar/features/library/data/library_providers.dart';
import 'package:doc_scan_ar/features/scanner/data/scan_session_provider.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

const _log = Logger('ScanSessionReviewPage');

/// Shown after each successful capture. Lets the user add more pages, drop
/// pages, and finalize the session into a new Document. On "Done" we also
/// auto-export the document as PDF or JPGs depending on the user's
/// `Default Save Format` setting.
class ScanSessionReviewPage extends ConsumerWidget {
  const ScanSessionReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scanSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Review pages')),
      body: session.pages.isEmpty
          ? const Center(child: Text('No pages yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: session.pages.length,
              itemBuilder: (context, i) => _Tile(
                index: i,
                onRemove: () =>
                    ref.read(scanSessionProvider.notifier).removePage(i),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text(S.addAnotherPage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: session.pages.isEmpty
                      ? null
                      : () => _onDone(context, ref),
                  icon: const Icon(Icons.check),
                  label: const Text(S.done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDone(BuildContext context, WidgetRef ref) async {
    final title = 'Scan ${DateFormat.yMMMd().add_Hm().format(DateTime.now())}';
    final docId = await ref
        .read(scanSessionProvider.notifier)
        .saveAsNewDocument(title: title);
    ref.invalidate(documentsProvider);

    // Auto-export per the user's Default Save Format setting.
    final fmt = ref.read(settingsControllerProvider).defaultSaveFormat;
    String? snackMsg;
    try {
      final db = await ref.read(dbServiceProvider.future);
      final doc = await db.getDocument(docId);
      final pages = await db.listPages(docId);
      if (doc != null && pages.isNotEmpty) {
        final exporter = ref.read(exportServiceProvider);
        if (fmt == DefaultSaveFormat.pdf) {
          final file = await exporter.exportPdf(doc: doc, pages: pages);
          snackMsg = 'Saved PDF: ${_displayName(file.path)}';
        } else {
          final files = await exporter.exportJpgs(doc: doc, pages: pages);
          snackMsg = 'Saved ${files.length} '
              '${files.length == 1 ? "JPG" : "JPGs"} to '
              '${_displayName(files.first.parent.path)}';
        }
      }
    } on Object catch (e, st) {
      _log.e('Auto-export after Done failed', e, st);
      snackMsg = 'Saved to library, but file export failed: $e';
    }

    if (!context.mounted) return;
    if (snackMsg != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(snackMsg)));
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  /// Trim the deep app-private prefix so the snackbar is readable.
  String _displayName(String path) {
    final marker = 'DocScanAR${Platform.pathSeparator}';
    final idx = path.indexOf(marker);
    if (idx < 0) return path;
    return path.substring(idx);
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.index, required this.onRemove});

  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scanSessionProvider);
    if (index >= session.pages.length) return const SizedBox.shrink();
    final bytes = session.pages[index];
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filledTonal(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ),
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page ${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
