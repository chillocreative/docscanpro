import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapControllerProvider);
    final controller = ref.read(iapControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final product = iap.products.isNotEmpty ? iap.products.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text(S.removeAds)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.workspace_premium,
              size: 88,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              S.paywallHeadline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${S.paywallSubhead}'
              ' ${product?.price ?? ''}'
              .trim(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            const _BulletRow('Remove every banner and interstitial.'),
            const _BulletRow('One payment — yours forever.'),
            const _BulletRow('All current and future premium features.'),
            const Spacer(),
            FilledButton(
              onPressed: iap.entitlement == AdEntitlement.active ||
                      iap.isPurchasePending
                  ? null
                  : controller.buyPremium,
              child: iap.isPurchasePending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      iap.entitlement == AdEntitlement.active
                          ? 'Active'
                          : S.paywallSubscribeCta,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
