import 'package:developer_workflow/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

  print('Permission status: ${settings.authorizationStatus}');

  final token = await messaging.getToken();

  print('FCM TOKEN: $token');

  await configureDependencies();

  runApp(const MyApp());
}
