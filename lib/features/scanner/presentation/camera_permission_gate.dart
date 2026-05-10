import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/features/scanner/data/camera_permission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gates [child] on the user having granted camera permission. If not, renders
/// a centered explainer with a CTA that requests permission (or opens system
/// settings if permanently denied).
class CameraPermissionGate extends ConsumerWidget {
  const CameraPermissionGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraPermissionProvider);

    return switch (state) {
      CameraPermissionState.unknown => const _Loading(),
      CameraPermissionState.granted => child,
      CameraPermissionState.denied => _PermissionPrompt(
          ctaLabel: S.permGrant,
          onPressed: () =>
              ref.read(cameraPermissionProvider.notifier).request(),
        ),
      CameraPermissionState.permanentlyDenied => _PermissionPrompt(
          ctaLabel: S.permOpenSettings,
          onPressed: () =>
              ref.read(cameraPermissionProvider.notifier).openSettings(),
        ),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({required this.ctaLabel, required this.onPressed});

  final String ctaLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              S.permCameraTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              S.permCameraBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPressed,
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
