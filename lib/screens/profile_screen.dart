import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import 'admin/admin_shell.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.isAdmin ?? false;

    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ')
            .map((w) => w[0].toUpperCase()).take(2).join()
        : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // ── Avatar card ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            color: AppTheme.accent, shape: BoxShape.circle),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(displayName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Badge(
                            label: 'Verified Account',
                            icon: Icons.verified_outlined,
                            color: AppTheme.success,
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            _Badge(
                              label: 'Admin',
                              icon: Icons.admin_panel_settings_outlined,
                              color: AppTheme.accent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Admin Panel shortcut ───────────────────────────────
                if (isAdmin) ...[
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminShell())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined,
                              color: AppTheme.accent, size: 20),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Panel',
                                    style: TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                Text('Manage products, orders & users',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppTheme.accent, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Account section ───────────────────────────────────
                _MenuSection(
                  title: 'Account',
                  items: [
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'My Orders',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      onTap: () => _comingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => _comingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _MenuSection(
                  title: 'Support',
                  items: [
                    _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Help Center',
                        onTap: () => _comingSoon(context)),
                    _MenuItem(
                        icon: Icons.policy_outlined,
                        label: 'Privacy Policy',
                        onTap: () => _comingSoon(context)),
                    _MenuItem(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        onTap: () => _comingSoon(context)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Sign out ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => _confirmSignOut(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppTheme.error.withOpacity(0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: AppTheme.error, size: 20),
                        SizedBox(width: 14),
                        Text('Sign Out',
                            style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Voltex v1.0.0',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Coming soon!',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: const Color(0xFF2C2C2C),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('You will need to sign in again.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false);
              }
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                      color: AppTheme.border, height: 1, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Icon(icon, color: AppTheme.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}