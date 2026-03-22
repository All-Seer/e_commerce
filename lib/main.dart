import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: VoltexApp()));
}

class VoltexApp extends StatelessWidget {
  const VoltexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voltex 5',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // Check once on startup if a user is already signed in
  final User? _initialUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // If already logged in from a previous session, go straight to Home
    if (_initialUser != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}