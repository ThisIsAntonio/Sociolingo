import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart ';
import 'package:chat_app/screens/welcome_screen.dart';
import 'package:chat_app/model/theme_provider.dart';

// A stream controller for handling language changes.
final StreamController<void> languageChangeStreamController =
    StreamController<void>.broadcast();

// The main entry point of the Flutter application.
void main() async {
  // Ensure that Flutter is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure that Easy Localization is initialized.
  await EasyLocalization.ensureInitialized();

  // Run the application with EasyLocalization widget as the root.
  runApp(
    EasyLocalization(
      // Define the supported locales for the app.
      supportedLocales: [Locale('en', ''), Locale('es', ''), Locale('fr', '')],
      // Specify the path where localization files are located.
      path: 'assets/languages',
      // Define the fallback locale in case the device locale is not supported.
      fallbackLocale: Locale('en', ''),
      // Specify whether to use fallback translations if the translation for the current locale is missing.
      useFallbackTranslations: true,
      // Child widget of EasyLocalization is the root of the app.
      child: MyApp(),
    ),
  );
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
            theme: ThemeData.light(), // Light theme data.
            darkTheme: ThemeData.dark(), // Dark theme data.
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            key: key, // Use the key for identifying widget for rebuild.
            home: WelcomeScreen(), // Set the home screen of the app.
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
