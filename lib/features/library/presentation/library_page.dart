import 'dart:io';

import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/services/db_service.dart';
import 'package:doc_scan_ar/core/services/storage_service.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/ads/presentation/banner_ad_view.dart';
import 'package:doc_scan_ar/features/export/data/export_service.dart';
import 'package:doc_scan_ar/features/library/data/library_providers.dart';
import 'package:doc_scan_ar/features/library/data/library_view_state.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:doc_scan_ar/features/paywall/presentation/paywall_page.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Home / "My Documents" tab.
///
/// Title + search bar always render so the screen never silently goes blank
/// when a provider is in loading/error state. The list area in the middle
/// switches between loading / error / empty / populated.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);
    final query = ref.watch(libraryQueryProvider);
    final isList = ref.watch(libraryIsListProvider);
    final adsHidden = ref.watch(adsHiddenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(isList: isList),
              const SizedBox(height: 16),
              _SearchField(initial: query),
              const SizedBox(height: 16),
              if (!adsHidden) ...[
                const _AdsBanner(),
                const SizedBox(height: 12),
              ],
              Expanded(child: _ListArea(docsAsync: docsAsync, query: query)),
              if (!adsHidden) const BannerAdView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListArea extends ConsumerWidget {
  const _ListArea({required this.docsAsync, required this.query});

  final AsyncValue<List<DocumentEntity>> docsAsync;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return docsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Loading documents…',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.pdfRed,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load documents:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(documentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (docs) {
        final filtered = _filter(docs, query);
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF9CA3AF),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    query.isEmpty
                        ? S.emptyDocuments
                        : 'No documents match "$query".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                  ),
                  if (query.isEmpty) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the blue camera button below to scan one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        final isList = ref.watch(libraryIsListProvider);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(documentsProvider),
          child: isList ? _DocList(docs: filtered) : _DocGrid(docs: filtered),
        );
      },
    );
  }

  static List<DocumentEntity> _filter(
    List<DocumentEntity> docs,
    String query,
  ) {
    if (query.trim().isEmpty) return docs;
    final q = query.toLowerCase();
    return docs.where((d) => d.title.toLowerCase().contains(q)).toList();
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.isList});

  final bool isList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            S.myDocuments,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        _ViewToggleButton(
          icon: Icons.grid_view_outlined,
          selected: !isList,
          onTap: () =>
              ref.read(libraryIsListProvider.notifier).state = false,
        ),
        const SizedBox(width: 8),
        _ViewToggleButton(
          icon: Icons.format_list_bulleted,
          selected: isList,
          onTap: () =>
              ref.read(libraryIsListProvider.notifier).state = true,
        ),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AppTheme.brandBlue : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({required this.initial});

  final String initial;

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) => ref.read(libraryQueryProvider.notifier).state = v,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
        hintText: S.searchDocumentsHint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.brandBlue, width: 1.4),
        ),
      ),
    );
  }
}

class _AdsBanner extends StatelessWidget {
  const _AdsBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFFDE68A)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.amberWarn,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: S.adsActiveTitle,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: S.adsActiveBody),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- helpers ----

/// Sum of all page-image file sizes for a document. Synchronous to keep the
/// list-cell build simple; on a typical document (few pages) this is
/// negligible (~1ms total).
int _docBytes(DocumentEntity d) {
  if (d.coverImagePath.isEmpty) return 0;
  // We don't have direct access to all pages here without an async query,
  // so we approximate: cover size × pageCount. Close enough for the chip
  // since pages from one scan session are usually similar in size.
  final f = File(d.coverImagePath);
  if (!f.existsSync()) return 0;
  return f.statSync().size *
      (d.pageCount == 0 ? 1 : d.pageCount);
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / kb).round()} KB';
}

class _DocList extends ConsumerWidget {
  const _DocList({required this.docs});

  final List<DocumentEntity> docs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _DocRow(doc: docs[i]),
    );
  }
}

class _DocGrid extends StatelessWidget {
  const _DocGrid({required this.docs});

  final List<DocumentEntity> docs;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Tall tile — tinted icon area + title + meta row + chip+size row.
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocGridTile(doc: docs[i]),
    );
  }
}

class _DocRow extends ConsumerWidget {
  const _DocRow({required this.doc});

  final DocumentEntity doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPdf = ref.watch(settingsControllerProvider).defaultSaveFormat ==
        DefaultSaveFormat.pdf;
    final size = _formatBytes(_docBytes(doc));
    final date = DateFormat('yyyy-MM-dd').format(doc.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDocumentActionsSheet(context, doc),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            _FileTypeBadge(isPdf: isPdf),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _FormatChip(isPdf: isPdf),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$date  •  $size',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocGridTile extends ConsumerWidget {
  const _DocGridTile({required this.doc});

  final DocumentEntity doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPdf = ref.watch(settingsControllerProvider).defaultSaveFormat ==
        DefaultSaveFormat.pdf;
    final size = _formatBytes(_docBytes(doc));
    final date = DateFormat('yyyy-MM-dd').format(doc.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDocumentActionsSheet(context, doc),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top tinted icon area
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF3F4F6),
                child: Center(
                  child: _FileTypeIcon(isPdf: isPdf, size: 60),
                ),
              ),
            ),
            // Bottom info area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _FormatChip(isPdf: isPdf),
                      const Spacer(),
                      Text(
                        size,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeBadge extends StatelessWidget {
  const _FileTypeBadge({required this.isPdf});

  final bool isPdf;
  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final bg = isPdf ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: _FileTypeIcon(isPdf: isPdf, size: size * 0.5)),
    );
  }
}

class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.isPdf, required this.size});

  final bool isPdf;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = isPdf ? AppTheme.pdfRed : AppTheme.brandBlue;
    return Icon(
      isPdf ? Icons.description : Icons.image_outlined,
      color: fg,
      size: size,
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.isPdf});

  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    final label = isPdf ? 'PDF' : 'JPG';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------- Document Actions bottom sheet ----------

/// Shows the Share / Download / Delete bottom sheet for [doc]. Replaces the
/// old three-dot menu on the card itself.
Future<void> showDocumentActionsSheet(
  BuildContext context,
  DocumentEntity doc,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _DocumentActionsSheet(doc: doc),
  );
}

class _DocumentActionsSheet extends ConsumerWidget {
  const _DocumentActionsSheet({required this.doc});

  final DocumentEntity doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
              child: Text(
                'Document Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.drive_file_rename_outline,
              iconColor: AppTheme.amberWarn,
              label: 'Rename',
              onTap: () => _rename(context, ref),
            ),
            _ActionRow(
              icon: Icons.share,
              iconColor: AppTheme.brandBlue,
              label: 'Share',
              onTap: () => _share(context, ref),
            ),
            _ActionRow(
              icon: Icons.download_outlined,
              iconColor: AppTheme.introIconGreen,
              label: 'Download',
              onTap: () => _download(context, ref),
            ),
            _ActionRow(
              icon: Icons.delete_outline,
              iconColor: AppTheme.pdfRed,
              label: 'Delete',
              onTap: () => _delete(context, ref),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF374151),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: doc.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty || newTitle == doc.title) {
      return;
    }
    final db = await ref.read(dbServiceProvider.future);
    await db.renameDocument(doc.id, newTitle);
    ref.invalidate(documentsProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close the actions sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Renamed to "$newTitle".')),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final files = await _exportFiles(context, ref);
    if (files.isEmpty) return;
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(exportServiceProvider).share(files, subject: doc.title);
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final files = await _exportFiles(context, ref);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (files.isEmpty) return;
    final paths = files.length == 1
        ? files.first.path
        : '${files.length} files in ${files.first.parent.path}';
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to: $paths')),
    );
  }

  Future<List<File>> _exportFiles(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final db = await ref.read(dbServiceProvider.future);
      final pages = await db.listPages(doc.id);
      if (pages.isEmpty) return [];
      final exporter = ref.read(exportServiceProvider);
      final fmt = ref.read(settingsControllerProvider).defaultSaveFormat;
      if (fmt == DefaultSaveFormat.pdf) {
        final pdf = await exporter.exportPdf(doc: doc, pages: pages);
        return [pdf];
      }
      return exporter.exportJpgs(doc: doc, pages: pages);
    } on Object catch (e) {
      if (!context.mounted) return [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
      return [];
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${doc.title}"?'),
        content: const Text('This will permanently remove the document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.pdfRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(S.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Delete page images on disk, then DB rows (cascade also removes page rows).
    final db = await ref.read(dbServiceProvider.future);
    final storage = ref.read(storageServiceProvider);
    final pages = await db.listPages(doc.id);
    for (final p in pages) {
      await storage.deletePageFile(p.imagePath);
    }
    await db.deleteDocument(doc.id);
    ref.invalidate(documentsProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close the sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${doc.title}".')),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
