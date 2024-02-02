import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chat_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';
  String _bio = '';

  // Updated to send data to your backend
  void _register() async {
    var url = Uri.parse(
        'http://10.0.2.2:3000/register'); // Adjust the URL for your environment
    try {
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': _username,
          'email': _email,
          'password': _password,
          'bio': _bio, // Assumes your backend handles this field correctly
          // 'profile_picture' is not included here as file handling is more complex and requires a different approach
        }),
      );

      if (response.statusCode == 201) {
        // Successful registration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User registered successfully')),
        );
        // Navigate to the LoginScreen after successful registration
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // Failed to register the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register user')),
        );
      }
    } catch (e) {
      // Error connecting to the server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to the server')),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _register();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize
              .min, // Ensures that the Row takes up the minimum space necessary
          children: [
            Image.asset(
              'lib/img/logo.png', // rute of your image
              fit: BoxFit.contain,
              height: 20.0, // Adjust the height as needed
            ),
            const SizedBox(width: 8.0), // Space between logo and text
            const Text('SocioLingo Chat - Register'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  onSaved: (value) => _username = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a username' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Please enter a valid email'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) => _password = value ?? '',
                  validator: (value) => value!.isEmpty || value.length < 6
                      ? 'Password must be at least 6 characters long'
                      : null,
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Bio (Optional)'),
                  onSaved: (value) => _bio = value ?? '',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
