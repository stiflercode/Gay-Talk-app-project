// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current Firebase user (nullable)
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes for listening
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with Google and returns the Firebase [User] on success.
  /// Returns null when the user cancels sign-in.
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // user aborted the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // rethrow as Exception for the UI to handle
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Signs in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Signs up with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Signs out from both GoogleSignIn and Firebase.
  /// Uses disconnect() instead of signOut() so account picker shows on next login.
  Future<void> signOut() async {
    try {
      // Disconnect completely so user sees account picker on next sign-in
      await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      // Fallback to regular signOut if disconnect fails
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (e2) {
        debugPrint('AuthService.signOut error: $e2');
      }
    }
  }
}
