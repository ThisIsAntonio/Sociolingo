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
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate sizes based on screen width
    double titleSize = screenWidth > 800 ? 28 : 24;
    double subtitleSize = screenWidth > 800 ? 18 : 14;
    double buttonWidth =
        screenWidth > 800 ? screenWidth * 0.4 : screenWidth * 0.85;
    double padding = screenWidth > 800 ? 30.0 : 16.0;
    double inputWidth =
        screenWidth > 800 ? screenWidth * 0.5 : screenWidth * 0.8;
    double fontSize = screenWidth > 800 ? 18 : 16;
    const fontColor = Color.fromARGB(255, 4, 33, 52);
    return Scaffold(
      appBar: AppBar(
        leading: Container(), // To remove the back button
        title: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  tr("forgotPassword_title"),
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  "forgotPassword_info",
                  style: TextStyle(fontSize: subtitleSize, color: fontColor),
                  textAlign: TextAlign.center,
                ).tr(),
                const SizedBox(height: 20),
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
                        '  ',
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
                // Email input
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: inputWidth),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "forgotPassword_yourEmail".tr(),
                      labelStyle: TextStyle(fontSize: fontSize),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return "forgotPassword_pleaseInsertValidEmail".tr();
                      }
                      return null;
                    },
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                const SizedBox(height: 30),
                // Forgot password Button
                Container(
                  width: buttonWidth,
                  child: ElevatedButton(
                    child: Text("forgotPassword_sendInstructions").tr(),
                    onPressed: _sendInstructions,
                    style: ElevatedButton.styleFrom(
                      //backgroundColor: Theme.of(context).primaryColor, // Background color
                      //brightness: Brightness.light;
                      backgroundColor: Color.fromRGBO(162, 245, 238, 1),
                      foregroundColor: Colors.black, // Text color
                      minimumSize: Size(double.infinity, 50), // Size of the bottom
                    ),                    
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
