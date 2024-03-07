import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/model/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  final String userEmail;

  const SettingsPage({Key? key, required this.userEmail}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Container(), // Para ocultar el botón de retroceso.
        title: Text(
          tr('settings_title'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 40),
          _buildButton(
            context,
            text: tr('settings_selectLanguage'),
            onPressed: () => _showLanguageDialog(context),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(tr('settings_darkModeSwitch')),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              themeProvider.themeMode =
                  value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const Divider(),
          _buildButton(
            context,
            text: tr('settings_deleteProfileButton'),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          const Divider(),
          _buildButton(
            context,
            text: tr('settings_aboutUsButton'),
            onPressed: () => _showAboutUsDialog(context),
          ),
          const Divider(),
          _buildButton(
            context,
            text: tr('settings_logOutButton'),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required String text, VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor, // Background color
          foregroundColor: Colors.white, // Text color
          minimumSize: Size(double.infinity, 50), // Size of the bottom
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
                          _updateUserLanguagePreference(locale.languageCode);
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

// Function to update user language preference in Firestore
  Future<void> _updateUserLanguagePreference(String languageCode) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'language_preference': languageCode,
    });
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
    try {
      // Get the user from the database
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Update the instance is_active to false
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_active': false,
      });

      // Show the confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('settings_accountDeletedMessage')),
          duration: const Duration(seconds: 3),
        ),
      );

      // Close the sesion and redirect to LoginScreen
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Show the error message if something went wrong
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

  // Function to logout of the app
  void _logout(BuildContext context) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String lastSeen = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Update the user state and last seen timestamp
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': false,
      'lastSeen': lastSeen,
    }).then((_) async {
      // Close the session
      await FirebaseAuth.instance.signOut();
      // Redirect to the loginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }).catchError((error) {
      // Error showing them on SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('settings_logoutError'))),
      );
    });
  }
}
