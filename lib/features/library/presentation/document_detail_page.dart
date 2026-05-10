import 'dart:io';

import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/core/services/storage_service.dart';
import 'package:doc_scan_ar/features/ads/data/ad_service.dart';
import 'package:doc_scan_ar/features/export/data/export_service.dart';
import 'package:doc_scan_ar/features/library/data/library_providers.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/ocr/presentation/ocr_progress_dialog.dart';
import 'package:doc_scan_ar/features/ocr/presentation/ocr_text_page.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-document page list with reorder + delete and a swipeable page viewer.
class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({required this.documentId, super.key});

  final int documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(documentPagesProvider(documentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pages'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) =>
                _onAction(context, ref, action, pagesAsync.valueOrNull ?? []),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text(S.exportPdf)),
              PopupMenuItem(value: 'jpg', child: Text(S.exportJpg)),
              PopupMenuItem(value: 'txt', child: Text(S.exportTxt)),
              PopupMenuDivider(),
              PopupMenuItem(value: 'ocr', child: Text(S.runOcr)),
              PopupMenuItem(value: 'ocrView', child: Text('View text')),
            ],
          ),
        ],
      ),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pages) {
          if (pages.isEmpty) {
            return const Center(child: Text('No pages in this document.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: pages.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, rawNewIndex) async {
              final newIndex =
                  rawNewIndex > oldIndex ? rawNewIndex - 1 : rawNewIndex;
              final reordered = [...pages];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              final tuples = <(int, int)>[
                for (var i = 0; i < reordered.length; i++)
                  (reordered[i].id, i),
              ];
              final db = await ref.read(dbServiceProvider.future);
              await db.reorderPages(documentId, tuples);
              ref.invalidate(documentPagesProvider(documentId));
            },
            itemBuilder: (context, i) {
              final page = pages[i];
              return _PageRow(
                key: ValueKey(page.id),
                index: i,
                page: page,
                onTap: () => _openViewer(context, pages, i),
                onDelete: () async {
                  final db = await ref.read(dbServiceProvider.future);
                  final storage = ref.read(storageServiceProvider);
                  await storage.deletePageFile(page.imagePath);
                  await db.deletePage(page.id);
                  ref
                    ..invalidate(documentPagesProvider(documentId))
                    ..invalidate(documentsProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext ctx, List<PageEntity> pages, int initial) {
    Navigator.of(ctx).push<void>(
      MaterialPageRoute(
        builder: (_) => _PageViewer(pages: pages, initial: initial),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    List<PageEntity> pages,
  ) async {
    if (pages.isEmpty) return;
    final db = await ref.read(dbServiceProvider.future);
    final docs = await db.listDocuments();
    final doc = docs.firstWhere((d) => d.id == documentId);
    final exporter = ref.read(exportServiceProvider);

    Future<void> snack(String msg) async {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> afterExport() async {
      ref.read(exportCounterProvider.notifier).increment();
      final n = ref.read(exportCounterProvider);
      if (shouldShowInterstitialAfter(n)) {
        await ref.read(adServiceProvider).maybeShowInterstitial();
      }
    }

    switch (action) {
      case 'pdf':
        final file = await exporter.exportPdf(doc: doc, pages: pages);
        await afterExport();
        await exporter.share([file], subject: doc.title);
        await snack('Saved ${file.path}');
      case 'jpg':
        final files = await exporter.exportJpgs(doc: doc, pages: pages);
        await afterExport();
        await exporter.share(files, subject: doc.title);
        await snack('Saved ${files.length} JPGs');
      case 'txt':
        final file = await exporter.exportTxt(doc: doc, pages: pages);
        if (file == null) {
          await snack('Run OCR first to export text.');
          return;
        }
        await afterExport();
        await exporter.share([file], subject: doc.title);
      case 'ocr':
        if (!context.mounted) return;
        final script =
            ref.read(settingsControllerProvider).ocrScript;
        await runOcrWithProgress(
          context: context,
          ref: ref,
          pages: pages,
          script: script,
        );
      case 'ocrView':
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => OcrTextPage(pages: pages),
          ),
        );
    }
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required super.key,
    required this.index,
    required this.page,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final PageEntity page;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final file = File(page.imagePath);
    return Dismissible(
      key: ValueKey('dismiss-${page.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${S.delete} page ${index + 1}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(S.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 56,
          height: 80,
          child: file.existsSync()
              ? Image.file(file, fit: BoxFit.cover)
              : const ColoredBox(color: Color(0xFFE5E7EB)),
        ),
        title: Text('Page ${index + 1}'),
        subtitle: page.ocrText == null
            ? const Text('No OCR yet')
            : Text(
                page.ocrText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}

class _PageViewer extends StatefulWidget {
  const _PageViewer({required this.pages, required this.initial});

  final List<PageEntity> pages;
  final int initial;

  @override
  State<_PageViewer> createState() => _PageViewerState();
}

class _PageViewerState extends State<_PageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Page ${_index + 1} / ${widget.pages.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final f = File(widget.pages[i].imagePath);
          if (!f.existsSync()) {
            return const Center(child: Icon(Icons.broken_image));
          }
          return InteractiveViewer(
            child: Center(child: Image.file(f)),
          );
        },
      ),
    );
  }
}
