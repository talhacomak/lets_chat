import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/router.dart';
import 'screens/sender_info/controllers/sender_user_data_controller.dart';
import 'utils/common/screens/error_screen.dart';
import 'screens/home/screens/home_screen.dart';
import 'screens/landing/screens/landing_screen.dart';
import 'utils/common/screens/loading_screen.dart';
import 'utils/common/providers/current_user_provider.dart';
import 'utils/constants/string_constants.dart';
import 'utils/constants/theme_constants.dart';
import './models/user.dart' as app;

/// Arka plan mesaj işleyici
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 [background] Mesaj alındı: ${message.messageId}');
}

/// Local Notification nesnesi
final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
String? activeChatUserId;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission();

  // Token al
  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // print('🔑 FCM Token: $fcmToken');

  // Arka plan mesaj işleyici bağla
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local Notification kurulumu
  await _initializeLocalNotifications();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

void _setupForegroundListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final senderId = data['senderId'];

    if (senderId != null && senderId == activeChatUserId) {
      print('📭 Notification didnt shown cause in the chat screen');
      return;
    }

    if (notification != null) {
      fln.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Notifications',
            importance: Importance.high,
          ),
        ),
      );
    }
  });
}


/// Local Notification başlangıç kurulumu
Future<void> _initializeLocalNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel',
    'Default Notifications',
    importance: Importance.high,
  );

  await fln.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const InitializationSettings settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await fln.initialize(settings);
  _setupForegroundListener();
}
class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

void debugToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  print('🔑 FCM Token: $token');
}

void checkAndSaveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final fcmInDb = userDoc.data()?['fcmToken'];

  if (fcmInDb == null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      print('📍 Eksik FCM token kaydedildi: $token');
    } else {
      print('⚠️ Token alınamadı.');
    }
  } else {
    print('✅ Kullanıcının FCM tokenı zaten kayıtlı.');
  }
}


class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'];
      if (chatId != null && mounted) {
        Navigator.pushNamed(context, '/chat', arguments: chatId);
      }
    });

    debugToken();
    checkAndSaveFcmToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StringsConsts.appName,
      theme: appTheme,
      home: _getHomeWidget(ref),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  Widget _getHomeWidget(WidgetRef ref) {
    return ref.watch(senderUserDataAuthProvider).when<Widget>(
      data: (app.User? user) {
        if (user == null) return const LandingScreen();
        currentUserProvider ??= Provider((ref) => user);
        return const HomeScreen();
      },
      error: (error, stackTrace) => ErrorScreen(error: error.toString()),
      loading: () => const LoadingScreen(),
    );
  }
}

