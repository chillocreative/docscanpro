import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/features/scanner/presentation/camera_permission_gate.dart';
import 'package:doc_scan_ar/features/scanner/presentation/camera_preview_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scan Document screen — dark surface with branded scan brackets, Auto
/// Detect / Auto Scan pills, and labeled Flash + Flip controls flanking the
/// shutter. Matches the `2026-05-09_16h58_29.jpg` design.
class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.scanDocument,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CameraPermissionGate(child: CameraPreviewView()),
            ),
          ],
        ),
      ),
    );
  }
}
