import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/welcome_screen.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:chat_app/model/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;
//import 'package:chat_app/model/topics_info.dart';
//import 'package:chat_app/model/user_test.dart';
//import 'package:chat_app/model/language_list.dart';

// A stream controller for handling language changes.
final StreamController<void> languageChangeStreamController =
    StreamController<void>.broadcast();

// Check if the device is IOS
bool isIOSDevice() {
  return js.context.hasProperty('isIOSDevice') &&
      js.context['isIOSDevice'] as bool;
}

// The main entry point of the Flutter application.
void main() async {
  // Ensure that Flutter is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure that Easy Localization is initialized.
  await EasyLocalization.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDb6GMwxxnc4O8Rh7Lw3TCG8jYCm1lui60",
          authDomain: "sociolingo-project.firebaseapp.com",
          projectId: "sociolingo-project",
          storageBucket: "sociolingo-project.appspot.com",
          messagingSenderId: "1065841467151",
          appId: "1:1065841467151:web:df66b762cde6a6ff0b687a",
          databaseURL:
              "https://sociolingo-project-default-rtdb.firebaseio.com/",
          measurementId: "G-D6SLD741Y9"),
    );
  } else {
    await Firebase.initializeApp()
        //.catchError((e) => print('Error inicializando Firebase: $e'));
        ;
  }

  // Initialize Firebase messaging.
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token;

  if (kIsWeb && !isIOSDevice()) {
    token = await messaging.getToken(
        vapidKey:
            "BBnEtMOtCc10zPV3w8-5w0odv6e7PcBIKOHlCKxv7_E9qtF0Jsb1HGK6n56yddlJLBeMZXBpdeQhkEjTmhYF-Ts");
  } else if (!kIsWeb) {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    token = await messaging.getToken();
    print('User granted permission: ${settings.authorizationStatus}');
  }

  print("Firebase Messaging Token: $token");

  if (token != null) {
    saveTokenToDatabase(token);
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Activate Firebase App Check.
  if (defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate();
  }

  // Loading topics and hobbies into the DBA (only one time or each time that the info is updated)
  // FirestoreDataLoader().uploadTopicsAndHobbies().then((_) {
  //   print("Topics and hobbies uploaded successfully!");
  // }).catchError((error) {
  //   print("Error uploading topics and hobbies: $error");
  // });
  // Loading user info into the DBA (only for testing)
  // UserSeeder userSeeder = UserSeeder();
  // userSeeder.seedUsers(90);
  // Loading languages into the DBA (only one time or each time that the info is updated)
  //await uploadLanguages();
  // Run the application with EasyLocalization widget as the root.
  runApp(
    EasyLocalization(
      // Define the supported locales for the app.
      supportedLocales: [Locale('en'), Locale('es'), Locale('fr')],
      // Specify the path where localization files are located.
      path: 'assets/languages',
      // Define the fallback locale in case the device locale is not supported.
      fallbackLocale: Locale('en'),
      // Specify whether to use fallback translations if the translation for the current locale is missing.
      useFallbackTranslations: true,
      // Child widget of EasyLocalization is the root of the app.
      child: MyApp(),
    ),
  );
}

// Function to save the FCM token to Firestore
void saveTokenToDatabase(String? token) async {
  String userId = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'messaging_token': token,
  });

  print('token updated.');
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

// This is the state class for the MyApp widget.
class _MyAppState extends State<MyApp> {
  // Initialize a unique key to identify this widget for rebuilding.
  Key key = UniqueKey();

  // Method to restart the app by updating the key, triggering a rebuild.
  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
// Provide a ThemeProvider to manage the app's theme.
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Return the MaterialApp widget with provided theme data.
          return MaterialApp(
            title: 'SocioLingo Chat',
            themeMode:
                themeProvider.themeMode, // Set theme mode based on provider.
            theme: ThemeData(
              // Light theme config
              brightness: Brightness.light,
              appBarTheme: AppBarTheme(
                backgroundColor:
                    Color.fromARGB(100, 18, 235, 214), // Light theme Color
                foregroundColor: Colors.black, // Light Text theme color
              ),
              buttonTheme: ButtonThemeData(
                  buttonColor: Color.fromARGB(100, 18, 235, 214)),
            ),
            darkTheme: ThemeData(
              // Dark theme config
              brightness: Brightness.dark,
              appBarTheme: AppBarTheme(
                backgroundColor:
                    Color.fromARGB(100, 18, 235, 214), // Dark theme color
                foregroundColor: Colors.white, // Dark Text theme color
              ),
              buttonTheme: ButtonThemeData(
                  buttonColor: Color.fromARGB(100, 18, 235, 214)),
            ),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            key: key, // Use the key for identifying widget for rebuild.
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    // the user is authenticate go to the MainScreen
                    return MainScreen(
                      userEmail: snapshot.data!.email!,
                    );
                  } else {
                    // the user is not authenticate go to welcome screen
                    return WelcomeScreen();
                  }
                }
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // close the StreamController to avoid memory leaks
    languageChangeStreamController.close();
    super.dispose();
  }
}

// This is the application widget which is a StatefulWidget, meaning it can change its internal state.
class MyApp extends StatefulWidget {
  // This is the function called to create the mutable state of this widget.
  @override
  _MyAppState createState() => _MyAppState();
}
