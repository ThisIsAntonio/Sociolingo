import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/verify_code_screen.dart';

// Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: ForgotPasswordForm(),
    );
  }
}

// Forgot Password Form
class ForgotPasswordForm extends StatefulWidget {
  @override
  _ForgotPasswordFormState createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String? email;

  void _sendInstructions() async {
    if (_formKey.currentState!.validate()) {
      String randomCode = _generateRandomCode();
      try {
        final url =
            Uri.parse('https://serverchat2.onrender.com/sendEmailInstructions');
        final response = await http.post(
          url,
          body:
              jsonEncode({'email': _emailController.text, 'code': randomCode}),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          print(tr('forgotPassword_emailSentSuccesfully'));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCodeScreen(
                userEmail: _emailController.text,
                randomCode: randomCode,
              ),
            ),
          );
        } else {
          print(tr('forgotPassword_errorSentEmail') + ' ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  String _generateRandomCode() {
    // Generate a random 6-digit code
    Random random = Random();
    int randomCode =
        random.nextInt(900000) + 100000; // Between 100000 and 999999
    return randomCode.toString();
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
                tr('forgotPassword_title'),
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              tr('forgotPassword_info'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: tr('forgotPassword_yourEmail'),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return tr('forgotPassword_pleaseInsertValidEmail');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text(tr('forgotPassword_sendInstructions')),
              onPressed: _sendInstructions,
            ),
          ],
        ),
      ),
    );
  }
}
