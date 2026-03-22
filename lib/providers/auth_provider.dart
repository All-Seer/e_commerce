import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simple loading/error state — navigation is handled imperatively in screens
class AuthState {
  final bool isLoading;
  final String? error;
  const AuthState({this.isLoading = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = const AuthState();
      return true; // success
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _message(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState();
      return true; // success
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _message(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }

  String _message(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Error ($code). Please try again.';
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());