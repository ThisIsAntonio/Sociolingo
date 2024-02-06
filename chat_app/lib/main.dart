import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart ';
import 'package:chat_app/screens/welcome_screen.dart';
import 'package:chat_app/model/theme_provider.dart';

final StreamController<void> languageChangeStreamController =
    StreamController<void>.broadcast();

// This is the main entry point of the application. It creates a Provider for ThemeData and passes it to all widgets in the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en', ''), Locale('es', ''), Locale('fr', '')],
      path: 'assets/languages',
      fallbackLocale: Locale('en', ''),
      useFallbackTranslations: true,
      //startLocale: Locale(
      //    'es', 'ES'), //<========this can change the language of all the app
      child: MyApp(),
    ),
  );
}

// This class is the root of your application.
class _MyAppState extends State<MyApp> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SocioLingo Chat',
            themeMode: themeProvider.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            key: key,
            home: WelcomeScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Asegúrate de cerrar el StreamController para evitar pérdidas de memoria
    languageChangeStreamController.close();
    super.dispose();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}
