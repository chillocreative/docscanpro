import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/providers/theme_mode_provider.dart';
import 'package:doc_scan_ar/core/services/logger.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:doc_scan_ar/features/paywall/data/iap_service.dart';
import 'package:doc_scan_ar/features/settings/data/settings_state.dart';
import 'package:doc_scan_ar/features/settings/presentation/legal_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    show TextRecognitionScript;
import 'package:url_launcher/url_launcher.dart';

const _log = Logger('SettingsPage');

/// Settings screen — orange Premium upsell card on top, then General /
/// Privacy & Security / Support sections.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: const [
            _Title(),
            SizedBox(height: 16),
            _PremiumCard(),
            SizedBox(height: 16),
            _GeneralSection(),
            SizedBox(height: 16),
            _PrivacySection(),
            SizedBox(height: 16),
            _SupportSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();
  @override
  Widget build(BuildContext context) => const Text(
        S.settingsTitle,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      );
}

class _PremiumCard extends ConsumerWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapControllerProvider);
    final controller = ref.read(iapControllerProvider.notifier);
    final active = iap.entitlement == AdEntitlement.active;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.premiumStart, AppTheme.premiumEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumEnd.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 26,
              ),
              SizedBox(width: 8),
              Text(
                S.premium,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            S.premiumSubhead,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              S.premiumPriceTag,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _PremiumBullet(label: S.premiumNoAds),
          const _PremiumBullet(label: S.premiumUnlimitedScans),
          const _PremiumBullet(label: S.premiumCloudBackup),
          const _PremiumBullet(label: S.premiumAdvancedFilters),
          const _PremiumBullet(label: S.premiumPrioritySupport),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: active || iap.isPurchasePending
                  ? null
                  : controller.buyPremium,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: iap.isPurchasePending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      active ? S.premiumActive : S.premiumSubscribeCta,
                      style: const TextStyle(
                        color: AppTheme.premiumEnd,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBullet extends StatelessWidget {
  const _PremiumBullet({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text(
            '✓',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 0, indent: 56, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF374151), size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsControllerProvider);
    return _SectionCard(
      title: S.sectionGeneral,
      children: [
        _SettingTile(
          icon: Icons.notifications_outlined,
          title: S.settingsNotifications,
          value: settings.notificationsEnabled ? 'On' : 'Off',
          onTap: () => ref
              .read(settingsControllerProvider.notifier)
              .setNotifications(enabled: !settings.notificationsEnabled),
        ),
        _SettingTile(
          icon: Icons.palette_outlined,
          title: S.settingsTheme,
          value: _themeLabel(mode),
          onTap: () => _cycleTheme(ref),
        ),
        _SettingTile(
          icon: Icons.smartphone_outlined,
          title: S.settingsDefaultSave,
          value: settings.defaultSaveFormat == DefaultSaveFormat.jpg
              ? 'JPG'
              : 'PDF',
          onTap: () =>
              ref.read(settingsControllerProvider.notifier).setDefaultSaveFormat(
                    settings.defaultSaveFormat == DefaultSaveFormat.pdf
                        ? DefaultSaveFormat.jpg
                        : DefaultSaveFormat.pdf,
                  ),
        ),
        _SettingTile(
          icon: Icons.text_fields_outlined,
          title: S.settingsOcrScript,
          value: ocrScriptShortName(settings.ocrScript),
          onTap: () => _pickOcrScript(context, ref, settings.ocrScript),
        ),
      ],
    );
  }

  Future<void> _pickOcrScript(
    BuildContext context,
    WidgetRef ref,
    TextRecognitionScript current,
  ) async {
    final picked = await showModalBottomSheet<TextRecognitionScript>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(
                    'OCR script',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Pick the writing system the recogniser should '
                    'target. Pages in other scripts still get a Latin '
                    'fallback automatically.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                RadioGroup<TextRecognitionScript>(
                  groupValue: current,
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                  child: Column(
                    children: [
                      for (final s in TextRecognitionScript.values)
                        RadioListTile<TextRecognitionScript>(
                          value: s,
                          title: Text(ocrScriptDisplayName(s)),
                          activeColor: AppTheme.brandBlue,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != current) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setOcrScript(picked);
    }
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static void _cycleTheme(WidgetRef ref) {
    final notifier = ref.read(themeModeProvider.notifier);
    notifier.state = switch (notifier.state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: S.sectionPrivacy,
      children: [
        _SettingTile(
          icon: Icons.lock_outline,
          title: S.settingsPrivacyPolicy,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
          ),
        ),
        _SettingTile(
          icon: Icons.description_outlined,
          title: S.settingsTerms,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
          ),
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: S.sectionSupport,
      children: [
        _SettingTile(
          icon: Icons.help_outline,
          title: S.settingsHelp,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const HelpCenterPage()),
          ),
        ),
        _SettingTile(
          icon: Icons.star_outline,
          title: S.settingsRate,
          onTap: () => _openRateApp(context),
        ),
        _SettingTile(
          icon: Icons.info_outline,
          title: S.settingsAbout,
          value: AppConstants.appVersionLabel,
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const AboutPage()),
          ),
        ),
      ],
    );
  }

  /// Open the Play Store listing for this app. Tries `market://` first
  /// (opens the Play Store app directly) and falls back to the https URL
  /// in a browser if Play isn't installed.
  Future<void> _openRateApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Future<bool> tryLaunch(String url) async {
      try {
        return await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } on Object catch (e, st) {
        _log.w('launchUrl failed for $url: $e\n$st');
        return false;
      }
    }

    if (await tryLaunch(AppConstants.playStoreMarketUrl)) return;
    if (await tryLaunch(AppConstants.playStoreHttpsUrl)) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open the Play Store. Please try again.'),
      ),
    );
  }
}
