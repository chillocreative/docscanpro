import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Read-only viewer for OCR'd text. Supports:
///  • per-page collapsible sections so the user can navigate long
///    documents without one giant scroll buffer
///  • in-text search with match highlight + counter
///  • copy entire document or copy individual pages
class OcrTextPage extends StatefulWidget {
  const OcrTextPage({required this.pages, super.key});

  final List<PageEntity> pages;

  @override
  State<OcrTextPage> createState() => _OcrTextPageState();
}

class _OcrTextPageState extends State<OcrTextPage> {
  final TextEditingController _query = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String get _allText {
    final buf = StringBuffer();
    for (final (i, p) in widget.pages.indexed) {
      final t = p.ocrText;
      if (t == null || t.isEmpty) continue;
      if (buf.isNotEmpty) buf.writeln();
      buf
        ..writeln('--- Page ${i + 1} ---')
        ..writeln(t);
    }
    return buf.toString();
  }

  int get _totalChars => widget.pages.fold<int>(
        0,
        (sum, p) => sum + (p.ocrText?.length ?? 0),
      );

  int get _pagesWithText => widget.pages
      .where((p) => p.ocrText != null && p.ocrText!.trim().isNotEmpty)
      .length;

  int get _matchCount {
    if (_q.isEmpty) return 0;
    final all = _allText.toLowerCase();
    final q = _q.toLowerCase();
    var count = 0;
    var i = 0;
    while (true) {
      final next = all.indexOf(q, i);
      if (next < 0) break;
      count++;
      i = next + q.length;
    }
    return count;
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = _pagesWithText > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Recognised text'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Copy all text',
            onPressed: hasAny ? () => _copy(_allText, 'All text') : null,
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ],
      ),
      body: hasAny ? _buildBody() : const _EmptyState(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchField(
                controller: _query,
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 8),
              _StatsRow(
                pagesWithText: _pagesWithText,
                totalPages: widget.pages.length,
                totalChars: _totalChars,
                matchCount: _q.isEmpty ? null : _matchCount,
                query: _q,
              ),
            ],
          ),
        ),
        const Divider(height: 0, color: Color(0xFFE5E7EB)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: widget.pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final page = widget.pages[i];
              return _PageSection(
                index: i,
                page: page,
                query: _q,
                onCopy: () => _copy(
                  page.ocrText ?? '',
                  'Page ${i + 1}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        hintText: 'Search in recognised text…',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.brandBlue, width: 1.4),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.pagesWithText,
    required this.totalPages,
    required this.totalChars,
    required this.query,
    this.matchCount,
  });

  final int pagesWithText;
  final int totalPages;
  final int totalChars;
  final int? matchCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      child: Row(
        children: [
          Text('$pagesWithText / $totalPages pages'),
          const SizedBox(width: 12),
          Text('$totalChars chars'),
          const Spacer(),
          if (matchCount != null)
            Text(
              query.isEmpty
                  ? ''
                  : matchCount == 0
                      ? 'No matches'
                      : '$matchCount '
                          '${matchCount == 1 ? 'match' : 'matches'}',
              style: TextStyle(
                color: matchCount == 0
                    ? const Color(0xFF9CA3AF)
                    : AppTheme.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _PageSection extends StatelessWidget {
  const _PageSection({
    required this.index,
    required this.page,
    required this.query,
    required this.onCopy,
  });

  final int index;
  final PageEntity page;
  final String query;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final t = (page.ocrText ?? '').trim();
    final matches =
        query.isEmpty ? 0 : _countMatches(t.toLowerCase(), query.toLowerCase());
    final hasText = t.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.brandBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasText
                      ? 'Page ${index + 1} · ${t.length} chars'
                      : 'Page ${index + 1} · no text recognised',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (query.isNotEmpty && hasText)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    matches == 0
                        ? '0'
                        : '$matches '
                            '${matches == 1 ? 'match' : 'matches'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: matches == 0
                          ? const Color(0xFF9CA3AF)
                          : AppTheme.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Copy this page',
                onPressed: hasText ? onCopy : null,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_outlined, size: 20),
              ),
            ],
          ),
          if (hasText) ...[
            const SizedBox(height: 6),
            _HighlightedText(text: t, query: query),
          ],
        ],
      ),
    );
  }

  static int _countMatches(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var c = 0;
    var i = 0;
    while (true) {
      final n = haystack.indexOf(needle, i);
      if (n < 0) break;
      c++;
      i = n + needle.length;
    }
    return c;
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: Color(0xFF111827),
    );
    if (query.isEmpty) {
      return SelectableText(text, style: body);
    }
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final highlight = body.copyWith(
      backgroundColor: const Color(0xFFFEF08A),
      color: const Color(0xFF92400E),
      fontWeight: FontWeight.w600,
    );
    var i = 0;
    while (i < text.length) {
      final next = lower.indexOf(q, i);
      if (next < 0) {
        spans.add(TextSpan(text: text.substring(i), style: body));
        break;
      }
      if (next > i) {
        spans.add(TextSpan(text: text.substring(i, next), style: body));
      }
      spans.add(
        TextSpan(
          text: text.substring(next, next + q.length),
          style: highlight,
        ),
      );
      i = next + q.length;
    }
    return SelectableText.rich(TextSpan(children: spans));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_fields,
              color: Color(0xFF9CA3AF),
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'No recognised text yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Run OCR on this document first.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
