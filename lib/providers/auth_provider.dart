import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Auth. Other providers watch [user] (via
/// the binding done in [AuthGate]) to know which Firestore subtree to
/// read/write.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      user = firebaseUser;
      notifyListeners();
    });
  }

  User? user;
  late final StreamSubscription<User?> _sub;

  bool get isSignedIn => user != null;

  Future<void> signIn({required String email, required String password}) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name);

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set({'name': name, 'email': email, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Turns a [FirebaseAuthException] code into the same plain-language copy
/// style the rest of the app uses.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'That email address doesn\'t look right.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists with that email.',
      'weak-password' => 'Choose a password with at least 8 characters.',
      'network-request-failed' => 'No internet connection. Try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}
