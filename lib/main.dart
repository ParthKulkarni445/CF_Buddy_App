import 'package:acex/auth_page.dart';
import 'package:acex/firebase_options.dart';
import 'package:acex/landing_page.dart';
import 'package:acex/notification_service.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:acex/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize FCM
  await NotificationService().initFCM();
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Colors.blue,
            cursorColor: Colors.blue,
          ),
          fontFamily: 'Poppins',
          primaryColor: Colors.white,
        ),
        home: const MyApp(),
      )
    ),
  );
}

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
    initialise();
  }

  void initialise() async{
    await authService.getUserData(context);
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if(Provider.of<UserProvider>(context).user.token.isEmpty){
      return const AuthPage();
    } else {
      return const LandingPage();
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // This handler will be called when the app is in the background or terminated
    print("Handling a background message: ${message.messageId}");
    print("Notification Title: ${message.notification?.title}");
    print("Notification Body: ${message.notification?.body}");
}