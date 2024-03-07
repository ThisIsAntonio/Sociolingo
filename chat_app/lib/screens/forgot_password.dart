import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

// Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("forgotPassword_title").tr(),
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

  // Function to send the instructions to change the password to the email address provided by the user
  void _sendInstructions() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("forgotPassword_emailSentSuccessfully").tr(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "forgotPassword_errorSentEmail").tr(),
          ),
        );
      }
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
                "forgotPassword_title",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).tr(),
            ),
            Text(
              "forgotPassword_info",
              textAlign: TextAlign.center,
            ).tr(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "forgotPassword_yourEmail".tr(),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return "forgotPassword_pleaseInsertValidEmail".tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text("forgotPassword_sendInstructions").tr(),
              onPressed: _sendInstructions,
            ),
          ],
        ),
      ),
    );
  }
}
