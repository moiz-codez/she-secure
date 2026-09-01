import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/sentinel_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'She Secure';
  await initializeSentinelService();
  await initializeMainIsolateNotifications();
  runApp(const SheSecureApp());
}
