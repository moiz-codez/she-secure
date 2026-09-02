import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/auth_provider.dart';
import '../services/profile_photo_service.dart';
import '../services/recording_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _city = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _deleting = false;
  String? _photoPath;

  String get _uid => context.read<AuthProvider>().user!.uid;

  @override
  void initState() {
    super.initState();
    // Firestore is the source of truth, not Firebase Auth's cached
    // displayName — that can lag behind (it only refreshes on ID-token
    // renewal), so a name saved from another session could take a while
    // to show up here, or never look in sync at all. age/city already
    // read from Firestore; name now does too, falling back to Auth's
    // cached value only if the document has nothing yet.
    FirebaseFirestore.instance.collection('users').doc(_uid).get().then((doc) async {
      if (!mounted) return;
      final data = doc.data();
      final path = await ProfilePhotoService.path();
      setState(() {
        _name.text = data?['name'] as String? ?? context.read<AuthProvider>().user?.displayName ?? '';
        _age.text = data?['age'] as String? ?? '';
        _city.text = data?['city'] as String? ?? '';
        _photoPath = File(path).existsSync() ? path : null;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1C29),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.text),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: AppColors.text),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    final path = await ProfilePhotoService.path();
    await File(picked.path).copy(path);
    await FirebaseFirestore.instance.collection('users').doc(_uid).set(
      {'photoUrl': path},
      SetOptions(merge: true),
    );
    if (!mounted) return;
    setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>().user!;
    await auth.updateDisplayName(_name.text.trim());
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({
      'name': _name.text.trim(),
      'age': _age.text.trim(),
      'city': _city.text.trim(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Saved.')));
  }

  Future<void> _sendPasswordReset() async {
    final email = context.read<AuthProvider>().user?.email;
    if (email == null) return;
    await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Password reset link sent to $email.')));
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().signOut();
    navigator.pushNamedAndRemoveUntil(Routes.auth, (route) => false);
  }

  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> ref) async {
    final docs = await ref.get();
    if (docs.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Firebase Auth's own account deletion can throw `requires-recent-login`
  /// if the session is old — asks for the password once and retries,
  /// rather than failing with no way forward.
  Future<bool> _reauthenticate() async {
    final email = context.read<AuthProvider>().user?.email;
    if (email == null) return false;
    final passwordCtrl = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm your password'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(passwordCtrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty) return false;
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account, trusted contacts, SOS history, and settings. '
          'Recordings already saved on this phone are also removed. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete account', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _performDelete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final reauthed = await _reauthenticate();
        if (reauthed) {
          await _performDelete();
        } else if (mounted) {
          setState(() => _deleting = false);
        }
        return;
      }
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Couldn\'t delete your account: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Couldn\'t delete your account: $e')));
      }
    }
  }

  Future<void> _performDelete() async {
    final uid = _uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    for (final name in ['contacts', 'sosHistory', 'settings', 'sentinelSamples', 'evidence']) {
      await _deleteCollection(userDoc.collection(name));
    }
    await userDoc.delete();

    final evidenceDir = await RecordingService.evidenceDirectory();
    if (await evidenceDir.exists()) await evidenceDir.delete(recursive: true);

    await FirebaseAuth.instance.currentUser!.delete();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.auth, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

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
                  const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.textMuted(0.1)),
                                image: _photoPath == null
                                    ? null
                                    : DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover),
                              ),
                              child: _photoPath == null
                                  ? Icon(Icons.person_outline_rounded, size: 40, color: AppColors.textMuted(0.35))
                                  : null,
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _pickPhoto,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.background, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          auth.profileName?.isNotEmpty == true ? auth.profileName! : 'She Secure user',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.45))),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileField(label: 'Full name', controller: _name),
                        const SizedBox(height: 15),
                        Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
                        const SizedBox(height: 6),
                        TextFormField(initialValue: user?.email ?? '', enabled: false),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _ProfileField(label: 'Age (optional)', controller: _age)),
                            const SizedBox(width: 11),
                            Expanded(flex: 2, child: _ProfileField(label: 'City (optional)', controller: _city)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: !_loaded || _saving ? null : _save,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                  )
                                : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _sendPasswordReset,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: BorderSide(color: AppColors.textMuted(0.16)),
                              padding: const EdgeInsets.all(13),
                              alignment: Alignment.centerLeft,
                            ),
                            icon: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted(0.55)),
                            label: const Text('Change password', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted(0.55),
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log out', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _deleting ? null : _deleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: _deleting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                              )
                            : const Icon(Icons.delete_forever_outlined, size: 18),
                        label: const Text('Delete account', style: TextStyle(fontSize: 14)),
                      ),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.68))),
        const SizedBox(height: 6),
        TextField(controller: controller),
      ],
    );
  }
}
