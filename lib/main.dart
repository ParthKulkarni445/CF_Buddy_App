import 'package:acex/auth_page.dart';
import 'package:acex/contests_page.dart';
import 'package:acex/firebase_options.dart';
import 'package:acex/landing_page.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:acex/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _flnp = FlutterLocalNotificationsPlugin();

const _channel = AndroidNotificationChannel(
  'contest_reminders',
  'Contest Reminders',
  description: 'Countdown to Codeforces contests',
  importance: Importance.high,
);

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _flnp
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  const androidInit = AndroidInitializationSettings('ic_stat_contest_reminder');
  const initSettings = InitializationSettings(android: androidInit);
  await _flnp.initialize(initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
    // handle taps on the notification itself or on action buttons
    final payload = resp.payload;
    final actionId = resp.actionId;
    if (actionId == 'id_1' && payload != null) { // Check for the specific action button ID
      // Handle "VIEW_CONTEST" action
      if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (_) => ContestsPage(),
          ),
        );
      }
    } else if (payload != null && actionId == null) {
      // This means the main notification body was tapped (not an action button)
      if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (_) => ContestsPage(),
          ),
        );
      }
    }
  });

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            textSelectionTheme: const TextSelectionThemeData(
              selectionHandleColor: Colors.blue,
              cursorColor: Colors.blue,
            ),
            fontFamily: 'Poppins',
            primaryColor: Colors.white,
          ),
          home: const MyApp(),
        )),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    NotificationService().initFCM(context);
    initialise();
  }

  void initialise() async {
    await authService.getUserData(context);
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (Provider.of<UserProvider>(context).user.token.isEmpty) {
      return const AuthPage();
    } else {
      return const LandingPage();
    }
  }
}

void _showLocalNotification(RemoteMessage msg, FlutterLocalNotificationsPlugin flnp) {
  final title = msg.data['title'];
  final body = msg.data['body'];
  final action = msg.data['action'];

  final androidDetails = AndroidNotificationDetails(
    _channel.id,
    _channel.name,
    channelDescription: _channel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_contest_reminder',
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      htmlFormatBigText: false,
      htmlFormatContentTitle: false,
    ),
    actions: action != null
        ? <AndroidNotificationAction>[
            AndroidNotificationAction(
              'id_1', // Unique ID for this action button
              action, // This will display "VIEW_CONTEST" on the button
              // For deeper links or specific actions, you might add a payload here
              // payload: 'contest_id_xyz',
              // context: AndroidActionContext.appContext, // Use appContext if you want to perform actions without opening the app immediately (e.g., mark as read)
            ),
            // You can add more buttons if needed
            // AndroidNotificationAction('id_2', 'Dismiss'),
          ]
        : null, // No actions if 'action' data is not provided
    // ------------------------------------------
  );
  
  final platformDetails = NotificationDetails(android: androidDetails);

  flnp.show(
    msg.hashCode,
    title,
    body,
    platformDetails,
    payload: 'action_payload_from_notification',
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1) ensure Flutter bindings & Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // --- RE-ADD THIS LINE ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensure you pass options here
  );
  // -----------------------

  // 2) make a fresh plugin instance
  final flnpBg = FlutterLocalNotificationsPlugin();

  // 3) recreate your channel
  await flnpBg
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // 4) initialize it (with correct icon)
  const androidInit = AndroidInitializationSettings('ic_stat_contest_reminder');
  await flnpBg.initialize(const InitializationSettings(android: androidInit));

  // 5) show the notification
  _showLocalNotification(message, flnpBg);
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  initFCM(BuildContext context) async {
    await _firebaseMessaging.requestPermission();

    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
    } else {
      print("Failed to get FCM token");
    }

    await _firebaseMessaging.subscribeToTopic('contest-reminders');

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      _showLocalNotification(msg, _flnp);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContestsPage()),
      );
    });
  }
}
