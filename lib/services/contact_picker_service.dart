import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/contact.dart';

/// Opens the native OS contact picker and maps the result onto our
/// [TrustedContact] model. Returns null if the user cancels, denies
/// permission, or picks a contact with no phone number.
class ContactPickerService {
  static Future<TrustedContact?> pick() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return null;

    final picked = await FlutterContacts.native.showPicker(properties: {ContactProperty.phone});
    if (picked == null || picked.phones.isEmpty) return null;

    final name = picked.displayName?.trim().isNotEmpty == true ? picked.displayName!.trim() : 'Contact';
    return TrustedContact(
      name: name,
      relation: 'Contact',
      phone: picked.phones.first.number,
      initials: name[0].toUpperCase(),
    );
  }
}
