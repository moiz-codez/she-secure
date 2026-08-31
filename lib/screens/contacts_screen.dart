import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

Future<void> _showAddContactDialog(BuildContext context, ContactsProvider contacts) async {
  if (contacts.contacts.length >= 5) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Your list is full — remove someone first.')));
    return;
  }
  final nameCtrl = TextEditingController();
  final relationCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add a trusted contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relation')),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty || phoneCtrl.text.trim().isEmpty) return;
            contacts.add(TrustedContact(
              name: name,
              relation: relationCtrl.text.trim().isEmpty ? 'Contact' : relationCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              initials: name[0].toUpperCase(),
            ));
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 21, color: AppColors.text),
                  ),
                  const Text(
                    'Trusted contacts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Text(
                      'These four people get your location the moment you fire an alert. Keep the list '
                      'short so the messages land fast.',
                      style: TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textMuted(0.55)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showNotBuiltSnack(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              minimumSize: const Size.fromHeight(46),
                            ),
                            icon: const Icon(Icons.contact_page_outlined, size: 17),
                            label: const Text('From phone', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddContactDialog(context, contacts),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: BorderSide(color: AppColors.textMuted(0.16)),
                              minimumSize: const Size.fromHeight(46),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add manually', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ON YOUR LIST', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                        Text(
                          '${contacts.contacts.length} of 5 added',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.4)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (var i = 0; i < contacts.contacts.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(
                                    contacts.contacts[i].initials,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accentLight),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(contacts.contacts[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text(
                                        '${contacts.contacts[i].relation} · ${contacts.contacts[i].phone}',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => showNotBuiltSnack(context),
                                  icon: Icon(Icons.edit_outlined, size: 17, color: AppColors.textMuted(0.5)),
                                ),
                                IconButton(
                                  onPressed: () => contacts.removeAt(i),
                                  icon: Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted(0.5)),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.only(top: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.textMuted(0.035), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentLight),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Tell them they are on your list. A message from an unknown app is easy to ignore.',
                                  style: TextStyle(fontSize: 11.5, height: 1.55, color: AppColors.textMuted(0.55)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
