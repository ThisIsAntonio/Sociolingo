import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Return a MaterialApp widget which is the root of the application.
    return MaterialApp(
      // Set the title of the application.
      title: 'SocioLingo',
      // Define the theme data for the application.
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set the primary color swatch to blue.
      ),
      // Set the home screen of the application to the WelcomeScreen widget.
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String appVersion = "";
  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version}+${info.buildNumber}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            // Title and subtitle
            Text(
              tr('w_mainTitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('w_mainTitle2'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Social Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // Distribute the buttons evenly
              children: [
                SocialButton(
                  iconPath: 'assets/img/facebook.png',
                  onPressed: () {
                    // Facebook action
                  },
                  size: 40.0, // Button size
                ),
                SocialButton(
                  iconPath: 'assets/img/google.png',
                  onPressed: () {
                    // Google action
                  },
                  size: 40.0, // Button size
                ),
                SocialButton(
                  iconPath: 'assets/img/apple.png',
                  onPressed: () {
                    // Apple action
                  },
                  size: 40.0, // Button size
                ),
              ],
            ),
            //const Spacer(),
            const SizedBox(height: 20),
            // line divider
            const Row(
              children: <Widget>[
                Expanded(
                  child: Divider(
                    color: Colors.white70,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'OR',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white70,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Button widget
            MaterialButton(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                // Navigate to registration screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()));
              },
              child: Text(tr('w_buttonSignUp')),
              textColor: Colors.black,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tr('w_existingAccount'),
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Navigate to the login screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                  child: Text(
                    tr('w_logIn'),
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),

            const Spacer(),
            Text(
              'Version $appVersion',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String iconPath; // Path to the icon image asset.
  final VoidCallback
      onPressed; // Function to be executed when the button is pressed.
  final double size; // Size of the button.

  // Constructor for the SocialButton class.
  const SocialButton({
    Key? key, // Optional parameter to specify the key for the widget.
    required this.iconPath, // Required parameter for the icon path.
    required this.onPressed, // Required parameter for the onPressed function.
    this.size = 24.0, // Default button size if not provided.
  }) : super(
            key:
                key); // Call the constructor of the StatelessWidget superclass.

  @override
  Widget build(BuildContext context) {
    // InkWell provides the ripple effect for touch feedback.
    // When tapped, it executes the onPressed function.
    return InkWell(
      onTap: onPressed,
      child: CircleAvatar(
        backgroundColor: Colors.white, // Circle white background
        radius: size / 2, // Set the radius of the circle avatar.
        child: ClipOval(
          // ClipOval clips its child (Image.asset) in an oval shape.
          child: Image.asset(
            iconPath, // Path to the icon image asset.
            width: size, // Set the width of the image.
            height: size, // Set the height of the image.
            fit: BoxFit
                .cover, // Scale the image to cover the entire circle avatar.
          ),
        ),
      ),
    );
  }
}
