import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _pollTimer;
  bool _resending = false;
  bool _resentSuccess = false;

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds — reload the user token and check emailVerified
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (verified && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resentSuccess = false;
    });
    await ref.read(authProvider.notifier).resendVerification();
    if (mounted) {
      setState(() {
        _resending = false;
        _resentSuccess = true;
      });
      // Reset the success badge after 4 s
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _resentSuccess = false);
      });
    }
  }

  Future<void> _backToLogin() async {
    // Sign out so the user can try a different account
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'your email address';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      color: AppTheme.accent, size: 38),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Check your email',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'We sent a verification link to\n$email',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click the link in the email to activate your account.\nThis screen will automatically continue once verified.',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Polling indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Waiting for verification…',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 32),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resending ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: BorderSide(
                          color: AppTheme.accent.withOpacity(0.5), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent),
                          )
                        : Icon(
                            _resentSuccess
                                ? Icons.check_circle_outline
                                : Icons.send_outlined,
                            size: 18,
                            color: _resentSuccess
                                ? AppTheme.success
                                : AppTheme.accent,
                          ),
                    label: Text(
                      _resentSuccess ? 'Email sent!' : 'Resend verification email',
                      style: TextStyle(
                        color: _resentSuccess
                            ? AppTheme.success
                            : AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to login
                TextButton(
                  onPressed: _backToLogin,
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
