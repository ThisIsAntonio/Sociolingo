import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/screens/login_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocioLingo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
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
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onPressed;
  final double size; // Add a parameter for size

  const SocialButton({
    Key? key,
    required this.iconPath,
    required this.onPressed,
    this.size = 24.0, // Default button size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: CircleAvatar(
        backgroundColor: Colors.white, // Circle white background
        radius: size / 2,
        child: ClipOval(
          child: Image.asset(
            iconPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
