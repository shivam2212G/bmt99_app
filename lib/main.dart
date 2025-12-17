import 'package:bmt99_app/screens/home_screen.dart';
import 'package:bmt99_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'model/notification_model.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------- HIVE INITIALIZATION ----------
  await Hive.initFlutter();
  Hive.registerAdapter(NotificationModelAdapter());
  await Hive.openBox<NotificationModel>('notifications');

  // ---------- ONESIGNAL INITIALIZATION ----------
  OneSignal.initialize("87fde30c-338e-497a-aa8a-5f2a6772b3d9");
  OneSignal.Notifications.requestPermission(true);

  // ---------- FOREGROUND NOTIFICATION LISTENER ----------
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    final notification = event.notification;

    Hive.box<NotificationModel>('notifications').add(
      NotificationModel(
        heading: notification.title ?? "No Title",
        content: notification.body,
        bigPicture: notification.bigPicture,
        receivedAt: DateTime.now(),
      ),
    );

    // Required for OneSignal v5
    event.preventDefault();
    event.notification.display();
  });

  // ---------- NOTIFICATION CLICK LISTENER ----------
  OneSignal.Notifications.addClickListener((event) {
    final notification = event.notification;

    Hive.box<NotificationModel>('notifications').add(
      NotificationModel(
        heading: notification.title ?? "No Title",
        content: notification.body,
        bigPicture: notification.bigPicture,
        receivedAt: DateTime.now(),
      ),
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMT 99',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(),
    );
  }
}
