import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/model/theme_provider.dart'; // Ensure you have defined this class as shown previously
//import 'package:chat_app/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Define SettingsPage as a StatelessWidget to manage theme changes through Provider.
class SettingsPage extends StatelessWidget {
  final String userEmail;

  const SettingsPage({Key? key, required this.userEmail}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Accessing ThemeProvider using Provider.of
    final themeProvider = Provider.of<ThemeProvider>(context);

    // void _changeLanguage(Locale locale) {
    //   context.setLocale(locale);
    //   languageChangeStreamController.add(null); // Emitir el evento
    // }

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
            // Delete account button
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => _showDeleteConfirmation(context),
              child: Text(tr('settings_deleteProfileButton')),
            ),
            const SizedBox(height: 45),
            // About us button
            ElevatedButton(
              onPressed: () {
                // Show about us dialog
                _showAboutUsDialog(context);
              },
              child: Text(tr('settings_aboutUsButton')),
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

  // Function to show the language dialog
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

  // Function to get the name of the language based on its locale code.
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

  // Function to show confirmation dialog before deleting user
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('settings_confirmDeleteTitle')),
          content: Text(tr('settings_confirmDeleteMessage')),
          actions: <Widget>[
            TextButton(
              child: Text(tr('settings_confirmDeleteNo')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(tr('settings_confirmDeleteYes')),
              onPressed: () {
                _deleteUser(context, userEmail);
              },
            ),
          ],
        );
      },
    );
  }

  // Function to delete user account from the database and logout of the app
  void _deleteUser(BuildContext context, String email) async {
    final response = await http.post(
      Uri.parse('https://serverchat2.onrender.com/deleteUser'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      // Showing message accepted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('settings_accountDeletedMessage')),
          duration: const Duration(seconds: 3),
        ),
      );
      // redirection to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      // Error to delete account
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('settings_errorDeleteAccount'),
      ));
    }
  }

  // Function to show about us dialog
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('settings_aboutUsDialogTitle')),
          content: SingleChildScrollView(
            child: Text(
              tr('settings_aboutUsDialogContent'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(tr('settings_aboutUsDialogCloseButton')),
            ),
          ],
        );
      },
    );
  }
}
