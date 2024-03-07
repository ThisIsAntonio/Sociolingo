import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/oldVersion/reset_password_screen.dart';

// Verify Code Screen
class VerifyCodeScreen extends StatelessWidget {
  final String randomCode;
  final String userEmail;

  VerifyCodeScreen({required this.userEmail, required this.randomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('verifyCode_title')),
      ),
      body: VerifyCodeForm(userEmail: userEmail, randomCode: randomCode),
    );
  }
}

// Verify Code Form
class VerifyCodeForm extends StatefulWidget {
  final String randomCode;
  final String userEmail;

  VerifyCodeForm({required this.userEmail, required this.randomCode});

  @override
  _VerifyCodeFormState createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  void _verifyCode() {
    if (_formKey.currentState!.validate()) {
      String enteredCode = _codeController.text;
      if (enteredCode == widget.randomCode) {
        // Navigate to Reset Password Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.userEmail),
          ),
        );
      } else {
        // Show error message for invalid code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('verifyCode_invalidVerificationCode')),
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
                tr('verifyCode_title'),
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              tr('verifyCode_checkYourEmail'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: tr('verifyCode_enterVerificationCode'),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('verifyCode_pleaseEnterVerificationCode');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Text(tr('verifyCode_enterVerificationCodeSubmit')),
              onPressed: _verifyCode,
            ),
          ],
        ),
      ),
    );
  }
}
