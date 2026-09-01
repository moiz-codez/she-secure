import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/contact.dart';

/// Trusted-contacts list, backed by `users/{uid}/contacts` in Firestore.
/// Call [bindUser] once a Firebase user is signed in and [unbind] on
/// sign-out — see [AuthGate].
class ContactsProvider extends ChangeNotifier {
  List<TrustedContact> _contacts = const [];
  List<String> _docIds = const [];
  CollectionReference<Map<String, dynamic>>? _collection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<TrustedContact> get contacts => _contacts;

  void bindUser(String uid) {
    _sub?.cancel();
    _collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('contacts');
    _sub = _collection!.snapshots().listen((snapshot) {
      _docIds = snapshot.docs.map((d) => d.id).toList();
      _contacts = snapshot.docs.map((d) {
        final data = d.data();
        return TrustedContact(
          name: data['name'] as String? ?? '',
          relation: data['relation'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          initials: data['initials'] as String? ?? '',
        );
      }).toList();
      notifyListeners();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _collection = null;
    _contacts = const [];
    _docIds = const [];
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.doc(_docIds[index]).delete();
  }

  Future<void> updateAt(int index, TrustedContact contact) async {
    final collection = _collection;
    if (collection == null) return;
    await collection.doc(_docIds[index]).update({
      'name': contact.name,
      'relation': contact.relation,
      'phone': contact.phone,
      'initials': contact.initials,
    });
  }

  Future<void> add(TrustedContact contact) async {
    final collection = _collection;
    if (collection == null || _contacts.length >= 5) return;
    await collection.add({
      'name': contact.name,
      'relation': contact.relation,
      'phone': contact.phone,
      'initials': contact.initials,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
