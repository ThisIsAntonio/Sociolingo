import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/login_screen.dart';

// Reset Password Screen
class ResetPasswordScreen extends StatelessWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('resetPassword_title')),
      ),
      body: ResetPasswordForm(email: email),
    );
  }
}

// Reset Password Form
class ResetPasswordForm extends StatefulWidget {
  final String email;

  ResetPasswordForm({required this.email});

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  void _resetPassword(String email, String newPassword) async {
    final url = Uri.parse('https://serverchat2.onrender.com/resetPassword');

    // Printing the info to check the password
    // print('Sending request to server: $url');
    // print('Request body: {"email": "$email", "newPassword": "$newPassword"}');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Password reset successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('resetPassword_passwordResetSuccessfully')),
          ),
        );
        // Navigate to Login Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        print('Error to update password: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('resetPassword_errorResettingPassword')),
          ),
        );
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('resetPassword_errorResettingPasswordTryAgain')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                tr('resetPassword_title'),
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              tr('resetPassword_enterNewPassword'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: tr('resetPassword_newPassword'),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return tr('resetPassword_newPasswordTooShort');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text(tr('resetPassword_resetPassword')),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _resetPassword(
                    widget.email,
                    _passwordController.text,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
