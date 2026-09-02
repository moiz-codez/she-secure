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

  /// The display name shown everywhere in the UI — sourced from Firestore's
  /// `users/{uid}.name`, not `user.displayName`. Firebase Auth's own
  /// displayName is a cached copy that only refreshes on ID-token renewal,
  /// so screens reading it directly could show a stale or empty name after
  /// Profile saved a new one, or never converge at all. Firestore is this
  /// app's actual source of truth for the name (see CLAUDE.md's schema);
  /// this listener is bound/unbound alongside every other per-user provider
  /// in `_AuthBinder`.
  String? profileName;
  DocumentReference<Map<String, dynamic>>? _profileDoc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  void bindProfile(String uid) {
    _profileSub?.cancel();
    _profileDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    _profileSub = _profileDoc!.snapshots().listen((snap) {
      profileName = snap.data()?['name'] as String?;
      notifyListeners();
    });
  }

  void unbindProfile() {
    _profileSub?.cancel();
    _profileSub = null;
    _profileDoc = null;
    profileName = null;
    notifyListeners();
  }

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
    _profileSub?.cancel();
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
