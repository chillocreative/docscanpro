import 'package:doc_scan_ar/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Re-usable scaffold for the long-form legal/info pages so all four screens
/// (Privacy, Terms, Help, About) share the same look — white background,
/// thin app bar, generous body padding, dark-grey body type.
class _DocScaffold extends StatelessWidget {
  const _DocScaffold({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: children,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.55,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocScaffold(
      title: 'Privacy Policy',
      children: [
        _Lead('Last updated: 10 May 2026'),
        _Body(
          'This Privacy Policy describes how '
          '${AppConstants.appName} ("the App", "we", "us") handles your '
          'information. By using the App you agree to the practices '
          'described below.',
        ),
        _SectionTitle('1. Data we do NOT collect'),
        _Body(
          '${AppConstants.appName} is designed to work entirely on your '
          'device. We do not run our own servers, we do not require you '
          'to create an account, and we do not transmit your scanned '
          'documents to us. The text recognised by the OCR engine, the '
          'images you capture, and the documents you save never leave '
          'your phone unless you explicitly share them through the '
          'system share sheet.',
        ),
        _SectionTitle('2. Data stored on your device'),
        _Body(
          '• Scanned page images and the SQLite database that catalogs '
          "them are stored in the App's private storage.\n"
          '• Settings such as your default save format, theme, and '
          'whether you have unlocked the lifetime Premium upgrade are '
          'stored in shared preferences.\n'
          '• OCR text extracted from your pages is stored alongside the '
          'page record in the same private database.',
        ),
        _SectionTitle('3. Camera and storage permissions'),
        _Body(
          'The App requests the camera permission so it can show a live '
          "preview and capture document scans. It uses Android's "
          'app-specific external storage (no broad storage permission '
          'is required) to write exported PDF and JPG files into '
          '/Android/data/${AppConstants.appPackage}/files/. You can '
          'revoke either permission at any time through Android '
          'Settings.',
        ),
        _SectionTitle('4. Third-party services'),
        _Body(
          'The App integrates with three Google services:\n'
          '• Google ML Kit Text Recognition — runs on-device. The model '
          'is downloaded once by Google Play services and processes '
          'your images locally.\n'
          '• Google Mobile Ads (AdMob) — when ads are enabled, AdMob '
          'may collect a limited set of identifiers (advertising ID, '
          'coarse network info) for ad delivery and frequency capping. '
          "Their handling is governed by Google's Privacy Policy.\n"
          '• Google Play Billing — used solely to process the optional '
          'lifetime Premium purchase. We never see your payment '
          'instrument; the App only receives an "entitled / not '
          'entitled" signal from Play.',
        ),
        _SectionTitle('5. Children'),
        _Body(
          'The App is not directed to children under 13. We do not '
          'knowingly collect personal data from children.',
        ),
        _SectionTitle('6. Your choices'),
        _Body(
          '• Delete a document inside the App to remove its image '
          'files and database rows from your device.\n'
          '• Uninstall the App to remove all of its private storage at '
          'once.\n'
          '• Disable the camera permission in Android Settings if you '
          'no longer want the App to access your camera.',
        ),
        _SectionTitle('7. Changes to this policy'),
        _Body(
          'We may update this policy from time to time. Material '
          'changes will be reflected in the "Last updated" date at the '
          'top of this page.',
        ),
        _SectionTitle('8. Contact'),
        _Body(
          'Questions or concerns about this policy can be sent to '
          '${AppConstants.supportEmail}.',
        ),
      ],
    );
  }
}

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DocScaffold(
      title: 'Terms of Service',
      children: [
        _Lead('Last updated: 10 May 2026'),
        _Body(
          'These Terms of Service ("Terms") govern your use of the '
          '${AppConstants.appName} mobile application. By installing or '
          'using the App you agree to these Terms.',
        ),
        _SectionTitle('1. License'),
        _Body(
          'We grant you a personal, non-exclusive, non-transferable, '
          'revocable license to install and use the App on Android '
          'devices that you own or control, solely for your personal or '
          'internal business purposes.',
        ),
        _SectionTitle('2. Acceptable use'),
        _Body(
          'You agree not to: (a) reverse engineer, decompile, or '
          'attempt to extract the source of the App except where such '
          'restriction is prohibited by law; (b) use the App to scan, '
          'store, or distribute content that you do not have the right '
          'to scan, store, or distribute; (c) use the App to violate '
          'any law or the rights of any third party.',
        ),
        _SectionTitle('3. Lifetime Premium purchase'),
        _Body(
          'The App offers a one-time, in-app purchase that unlocks '
          'Premium features for the lifetime of the App on the Google '
          'account that made the purchase. The purchase is processed by '
          "Google Play Billing and is governed by Google's payment and "
          'refund policies. "Lifetime" refers to the lifetime of the '
          "App's availability on the Google Play Store and does not "
          'guarantee perpetual availability of any specific feature or '
          'service.',
        ),
        _SectionTitle('4. Your content'),
        _Body(
          'You retain all rights to the documents, images, and text '
          'you scan or generate with the App. We claim no ownership '
          'over your content. Because the App stores your content on '
          'your device, you are responsible for backing it up.',
        ),
        _SectionTitle('5. No warranty'),
        _Body(
          'The App is provided "as is" and "as available" without '
          'warranties of any kind, either express or implied, '
          'including but not limited to merchantability, fitness for a '
          'particular purpose, accuracy of OCR output, or '
          'non-infringement. We do not warrant that the App will be '
          'uninterrupted, error-free, or free of harmful components.',
        ),
        _SectionTitle('6. Limitation of liability'),
        _Body(
          'To the fullest extent permitted by law, we shall not be '
          'liable for any indirect, incidental, special, consequential, '
          'or punitive damages, or any loss of data, profits, or '
          'goodwill, arising from your use of the App. Our total '
          'liability for any claim arising out of or relating to the '
          'App shall not exceed the amount you paid for it (if any) in '
          'the twelve months preceding the claim.',
        ),
        _SectionTitle('7. Termination'),
        _Body(
          'You may stop using the App at any time by uninstalling it. '
          'We may suspend or terminate your access if you breach these '
          'Terms or use the App in a way that creates risk for us or '
          'other users.',
        ),
        _SectionTitle('8. Changes'),
        _Body(
          'We may update these Terms when we add features or to reflect '
          'changes in law. Continued use of the App after an update '
          'constitutes acceptance of the revised Terms.',
        ),
        _SectionTitle('9. Contact'),
        _Body(
          'Questions about these Terms? Reach the developer at '
          '${AppConstants.supportEmail}.',
        ),
      ],
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocScaffold(
      title: 'Help Center',
      children: [
        const _Lead(
          'Quick answers to the questions we hear most. Need '
          'something else? Contact the developer below.',
        ),
        const _SectionTitle('Getting started'),
        const _Body(
          'Tap the blue camera button in the bottom bar to capture a '
          'page. Hold your phone roughly parallel to the document; the '
          'detector highlights the four corners and turns green when '
          'the framing is steady. After capture you can fine-tune the '
          'corners, pick a filter, and add more pages before saving.',
        ),
        const _SectionTitle('Default save format'),
        const _Body(
          'Settings → General → Default Save Format lets you choose PDF '
          'or JPG. The app strictly follows this choice — every '
          'auto-export, library download, and share action will use '
          'the format you picked.',
        ),
        const _SectionTitle('OCR'),
        const _Body(
          'Open a document, choose "Run OCR" from the menu, and the '
          'app will extract text from every page on-device using '
          'Google ML Kit. You can then export the recognised text as '
          'a .txt file or copy it from the "View text" screen.',
        ),
        const _SectionTitle('Premium / Remove Ads'),
        const _Body(
          'The lifetime Premium purchase removes all ads, unlocks '
          'unlimited scans, advanced filters, cloud backup hooks, and '
          'priority support. It is a one-time payment of '
          '${AppConstants.premiumPriceCopy} processed through Google '
          "Play. Refunds are handled by Google's standard Play Store "
          'policy.',
        ),
        const _SectionTitle('My scans look skewed'),
        const _Body(
          'Use Adjust Corners on the editor screen to drag each pip to '
          'the precise corner of the document. The app then warps the '
          'page so it appears as if shot straight-on.',
        ),
        const _SectionTitle('Where are my exported files?'),
        const _Body(
          'Exported PDFs and JPGs are written to '
          '/Android/data/${AppConstants.appPackage}/files/Documents (or '
          '/Pictures for JPGs). Use the share sheet from the document '
          'actions menu to send them anywhere — Drive, Gmail, '
          'WhatsApp, etc.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    color: Color(0xFF1D4ED8),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Contact the developer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'For bug reports, feature ideas, or anything not '
                'covered above, email the developer directly. We '
                'usually reply within a couple of business days.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E3A8A),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 10),
              SelectableText(
                AppConstants.supportEmail,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocScaffold(
      title: 'About',
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 44,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            AppConstants.appVersionLabel,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        const _SectionTitle('What is ${AppConstants.appName}?'),
        const _Body(
          '${AppConstants.appName} is a fast, privacy-friendly document '
          'scanner built for Android. Point your camera at any page — a '
          'receipt, a notebook, an ID card, a contract — and the app '
          'finds the four corners in real time, warps the page to a '
          'flat scan, and lets you save or share it as a polished PDF '
          'or JPG. Everything happens on your device.',
        ),
        const _SectionTitle('Highlights'),
        const _FeatureRow(
          icon: Icons.auto_awesome,
          title: 'Live edge detection',
          subtitle:
              'A real-time finder traces the document in the camera '
              'preview and turns green when the framing is steady.',
        ),
        const _FeatureRow(
          icon: Icons.crop_free,
          title: '4-corner adjuster',
          subtitle:
              'Fine-tune each corner with a magnifier loupe before the '
              'perspective warp is applied.',
        ),
        const _FeatureRow(
          icon: Icons.tune,
          title: 'Five tuned filters',
          subtitle:
              'Original, Auto-Enhance, Grayscale, Black & White, and '
              'Magic Color — switch instantly to find the cleanest '
              'look.',
        ),
        const _FeatureRow(
          icon: Icons.text_snippet_outlined,
          title: 'On-device OCR',
          subtitle:
              'Google ML Kit extracts text from every page locally. '
              'No upload, no account, no waiting on a server.',
        ),
        const _FeatureRow(
          icon: Icons.picture_as_pdf_outlined,
          title: 'PDF & JPG export',
          subtitle:
              'Save multi-page documents as PDFs or one-JPG-per-page. '
              'Share through any app installed on your phone.',
        ),
        const _FeatureRow(
          icon: Icons.folder_special_outlined,
          title: 'Multi-page library',
          subtitle:
              'Reorder pages, rename documents, search by title, and '
              'switch between list and grid views.',
        ),
        const _FeatureRow(
          icon: Icons.lock_outline,
          title: 'Privacy by default',
          subtitle:
              "Documents stay in the app's private storage and never "
              'leave your device unless you choose to share them.',
        ),
        const _FeatureRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Lifetime Premium',
          subtitle:
              'A single ${AppConstants.premiumPriceCopy} payment '
              'removes ads, unlocks unlimited scans, advanced filters, '
              'cloud backup hooks, and priority support — forever.',
        ),
        const _SectionTitle('Credits'),
        const _Body(
          'Built with Flutter. Edge detection runs in pure Dart; OCR '
          'is powered by Google ML Kit; in-app purchases use Google '
          'Play Billing. Document export uses the open-source `pdf` '
          'and `printing` packages.',
        ),
        const _SectionTitle('Contact'),
        const _Body(
          'For support or feedback, email '
          '${AppConstants.supportEmail}.',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1D4ED8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
