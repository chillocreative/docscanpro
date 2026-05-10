import 'dart:async';

import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/library/domain/document.dart';
import 'package:doc_scan_ar/features/ocr/data/ocr_service.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    show TextRecognitionScript;

/// Shows a non-dismissable AlertDialog while OCR runs over [pages].
///
/// While the dialog is up the user sees:
///   â€¢ a progress bar driven by [OcrProgress.fraction]
///   â€¢ "Processing page N of M" copy
///   â€¢ the running script (Latin, Japanese, â€¦)
///
/// When the run finishes the dialog auto-closes and a snackbar reports
/// how many pages succeeded vs. errored.
Future<void> runOcrWithProgress({
  required BuildContext context,
  required WidgetRef ref,
  required List<PageEntity> pages,
  required TextRecognitionScript script,
}) async {
  if (pages.isEmpty) return;

  final progress = ValueNotifier<OcrProgress>(
    OcrProgress(completed: 0, total: pages.length),
  );
  final errors = <String>[];

  final ocrFuture = ref.read(ocrServiceProvider).runOnAll(
        pages,
        script: script,
        onProgress: (p) {
          progress.value = p;
          if (p.lastError != null) errors.add(p.lastError!);
        },
      );

  // Show the dialog. The dialog itself does not await the OCR; it just
  // listens to the progress stream. When OCR completes we pop().
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OcrProgressDialog(
        progress: progress,
        script: script,
      ),
    ),
  );

  await ocrFuture;

  // Close the dialog if it's still up.
  if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  progress.dispose();
  if (!context.mounted) return;
  final completed = pages.length - errors.length;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          errors.isEmpty
              ? 'OCR complete â€” $completed '
                  '${completed == 1 ? 'page' : 'pages'} processed.'
              : 'OCR finished with ${errors.length} error(s); '
                  '$completed of ${pages.length} pages processed.',
        ),
        action: errors.isEmpty
            ? null
            : SnackBarAction(
                label: 'Details',
                onPressed: () => _showErrorList(context, errors),
              ),
      ),
    );
}

void _showErrorList(BuildContext context, List<String> errors) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('OCR errors'),
      content: SizedBox(
        width: 320,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: errors.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(errors[i]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Inner dialog widget â€” listens to a `ValueNotifier<OcrProgress>` so
/// we don't need a StreamController for what is effectively a single
/// monotonic counter.
class _OcrProgressDialog extends StatelessWidget {
  const _OcrProgressDialog({
    required this.progress,
    required this.script,
  });

  final ValueNotifier<OcrProgress> progress;
  final TextRecognitionScript script;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.text_fields,
            color: AppTheme.brandBlue,
          ),
          SizedBox(width: 10),
          Text('Recognising text'),
        ],
      ),
      content: ValueListenableBuilder<OcrProgress>(
        valueListenable: progress,
        builder: (context, p, _) {
          final scriptName = ocrScriptShortName(script);
          return SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing page ${p.completed.clamp(1, p.total)} '
                  'of ${p.total}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Script: $scriptName Â· on-device',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: p.fraction,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.brandBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(p.fraction * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
