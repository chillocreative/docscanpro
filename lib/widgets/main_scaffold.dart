import 'package:doc_scan_ar/core/l10n/strings_en.dart';
import 'package:doc_scan_ar/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell. Three branches map to:
///   index 0 → /home   (Home tile, left)
///   index 1 → /scan   (Camera FAB, center, visually prominent)
///   index 2 → /settings (Settings tile, right)
///
/// The Camera entry IS a real shell branch so the bottom bar remains
/// visible on the scan page (matches the screenshot).
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _go(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final i = shell.currentIndex;
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomBar(
        homeSelected: i == 0,
        cameraSelected: i == 1,
        settingsSelected: i == 2,
        onTap: _go,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.homeSelected,
    required this.cameraSelected,
    required this.settingsSelected,
    required this.onTap,
  });

  final bool homeSelected;
  final bool cameraSelected;
  final bool settingsSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              Expanded(
                child: _NavTile(
                  icon: Icons.home_outlined,
                  filledIcon: Icons.home,
                  label: S.navHome,
                  selected: homeSelected,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _CameraTile(
                  selected: cameraSelected,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavTile(
                  icon: Icons.settings_outlined,
                  filledIcon: Icons.settings,
                  label: S.navSettings,
                  selected: settingsSelected,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandBlue : const Color(0xFF6B7280);
    return InkResponse(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? filledIcon : icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.brandBlue : const Color(0xFFD1D5DB);
    return Center(
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.brandBlue.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: const Icon(
            Icons.photo_camera,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}
