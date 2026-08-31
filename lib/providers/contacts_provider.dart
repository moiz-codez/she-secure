import 'package:flutter/foundation.dart';

import '../models/contact.dart';

/// Trusted-contacts list. Phase 1 keeps this in memory with the same seed
/// data the design canvas used; Phase 2 swaps the backing store for
/// Firestore without changing this provider's public shape.
class ContactsProvider extends ChangeNotifier {
  final List<TrustedContact> _contacts = [
    const TrustedContact(name: 'Ammi', relation: 'Mother', phone: '0300 232 4412', initials: 'A'),
    const TrustedContact(name: 'Zainab', relation: 'Sister', phone: '0321 887 1188', initials: 'Z'),
    const TrustedContact(name: 'Hira', relation: 'Flatmate', phone: '0333 504 9004', initials: 'H'),
    const TrustedContact(name: 'Bilal', relation: 'Colleague', phone: '0345 771 2257', initials: 'B'),
  ];

  List<TrustedContact> get contacts => List.unmodifiable(_contacts);

  void removeAt(int index) {
    _contacts.removeAt(index);
    notifyListeners();
  }

  void add(TrustedContact contact) {
    if (_contacts.length >= 5) return;
    _contacts.add(contact);
    notifyListeners();
  }
}
