import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/model/theme_provider.dart'; // Ensure you have defined this class as shown previously
import 'package:chat_app/main.dart';

// Define SettingsPage as a StatelessWidget to manage theme changes through Provider.
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Accessing ThemeProvider using Provider.of
    final themeProvider = Provider.of<ThemeProvider>(context);

    void _changeLanguage(Locale locale) {
      context.setLocale(locale);
      languageChangeStreamController.add(null); // Emitir el evento
    }

    // Build the UI of SettingsPage
    return Scaffold(
      appBar: AppBar(
        leading: Container(), // Hide the back button.
        title: Column(
          mainAxisSize:
              MainAxisSize.max, // To occupy the minimum space necessary.
          mainAxisAlignment:
              MainAxisAlignment.center, // Center vertically on the AppBar.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Stretch the children along the crossed axis.
          children: [
            Text(
              tr('settings_title'),
              textAlign: TextAlign.start, // Center the text
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 25),
            // Language dropdownButton
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(tr('settings_selectLanguage')), // Change Language
                  Text(
                    _localeName(context.locale),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              onTap: () => _showLanguageDialog(context),
            ),
            const SizedBox(height: 25),
            // Theme switcherbuttons
            ListTile(
              title: Text(tr('settings_darkModeSwitch')),
              // Using a Switch to toggle between dark and light theme
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  // Updating the themeMode in ThemeProvider which triggers UI rebuild
                  themeProvider.themeMode =
                      value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            const SizedBox(height: 45),
            // Log out button
            ElevatedButton(
              onPressed: () {
                // Logging out and redirecting user to LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) =>
                      false, // Removing all previous routes
                );
              },
              child: Text(tr('settings_logOutButton')),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('settings_languageDropdown')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Locale>[
                Locale('en', ''),
                Locale('es', ''),
                Locale('fr', ''),
              ]
                  .map((locale) => ListTile(
                        title: Text(_localeName(locale)),
                        onTap: () {
                          context.setLocale(locale);
                          Navigator.of(context).pop();
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  String _localeName(Locale locale) {
    switch (locale.toString()) {
      case 'en':
        return tr('settings_EnglishLanguage');
      case 'es':
        return tr('settings_SpanishLanguage');
      case 'fr':
        return tr('settings_frenchLanguage');
      default:
        return locale.toString();
    }
  }
}
