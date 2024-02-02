import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/model/theme_provider.dart'; // Ensure you have defined this class as shown previously

// Define SettingsPage as a StatelessWidget to manage theme changes through Provider.
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Accessing ThemeProvider using Provider.of
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SocioLingo Chat - Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              title: const Text('Dark Mode'),
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
            ElevatedButton(
              onPressed: () {
                // Logging out and redirecting user to LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) =>
                      false, // Removing all previous routes
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
