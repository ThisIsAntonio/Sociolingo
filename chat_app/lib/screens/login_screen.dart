import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/forgot_password.dart';
import 'package:chat_app/screens/main_screen.dart';

// Define the LoginScreen widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// Define the state for LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variables to store user input
  String _email = '';
  String _password = '';

  // Function to handle user login
  void _login() async {
    var url = Uri.parse(
        'https://serverchat2.onrender.com/login'); // Adjust the URL for your environment //localhost is 100.20.92.101:300
    try {
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _email,
          'password': _password,
        }),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        // Login successful
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('login_successful'))));

        var data = jsonDecode(response.body);
        String userEmail = data['email'];

        // Navigate to the MainScreen
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MainScreen(userEmail: userEmail)));
      } else {
        // Login failed
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('login_failed'))));
      }
    } catch (e) {
      // Handle errors in sending the request or receiving the response
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('login_errorConnecting'))));
    }
  }

  // Function to submit the login form
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                // Title
                Text(
                  tr('login_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Program Logo
                CircleAvatar(
                  radius: 60, // Adjust the size to your liking
                  backgroundColor: Colors.transparent, // Transparent background
                  child: ClipOval(
                    child:
                        Image.asset('assets/img/logo.png', // rute of your image
                            fit: BoxFit.cover, // Cover the space of the circle
                            width: 120, // Adjust the width
                            height: 120), //Adjust the height
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  tr('login_subtitle'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                // Social Media Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // Distribuye los botones uniformemente
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
                const SizedBox(height: 25),
                // Divider
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
                const SizedBox(height: 30),
                // Field TextFormField for Email and Password
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return tr('login_invalidPassword');
                    }
                    return null;
                  },
                ),
                // Password
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) => _password = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 5) {
                      return tr('login_errorLongPassword');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Login Button
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(tr('login_buttonLogin')),
                ),
                // Forgot Password Button
                TextButton(
                  onPressed: () {
                    // Navigate to RegisterScreen when button is pressed
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen()));
                  },
                  child: Text(tr("login_buttonForgotPassword")),
                ),
              ],
            ),
          ),
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
        backgroundColor: Colors.white, // Fondo blanco del círculo
        radius: size / 2, // El radio se basa en el tamaño proporcionado
        child: ClipOval(
          child: Image.asset(
            iconPath,
            width: size, // Ajusta la anchura basada en el tamaño proporcionado
            height: size, // Ajusta la altura basada en el tamaño proporcionado
            fit: BoxFit.cover, // Cubre el área del widget sin deformarse
          ),
        ),
      ),
    );
  }
}
