import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom nav used on Home, History, Vets, Profile.
/// Scan is a raised center action rather than a normal tab, since it's
/// the app's primary action.
class PupCheckBottomNav extends StatelessWidget {
  final String current; // 'home' | 'history' | 'vets' | 'profile' | 'analyze'

  const PupCheckBottomNav({super.key, required this.current});

  void _go(BuildContext context, String route) {
    if (route == '/${current}') return;
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 18, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: current == 'home', onTap: () => _go(context, '/home')),
          _NavItem(icon: Icons.history_rounded, label: 'History', active: current == 'history', onTap: () => _go(context, '/history')),
          _ScanButton(onTap: () => Navigator.pushNamed(context, '/analyze')),
          _NavItem(icon: Icons.place_rounded, label: 'Vets', active: current == 'vets', onTap: () => _go(context, '/vets')),
          _NavItem(icon: Icons.person_rounded, label: 'Profile', active: current == 'profile', onTap: () => _go(context, '/profile')),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.inkSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
Widget build(BuildContext context) {
  return Transform.translate(
    offset: const Offset(0, -28),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    ),
  );
}
}
