import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/forgot_password.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chat_app/model/MathChallenge.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chat_app/screens/topics_screen.dart';
//import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Define the LoginScreen widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// Define the state for LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mathChallenge = MathChallenge();
  final _mathAnswerController = TextEditingController();

  // Variables to store user input
  String _email = '';
  String _password = '';
  String lastSeen = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Dispose
  @override
  void dispose() {
    _mathAnswerController.dispose();
    super.dispose();
  }

  // Function to handle user login with Firebase
  void _login() async {
    try {
      // Sign in with email and password using Firebase
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      final User? user = userCredential.user;
      //print('user email ${userCredential} ');

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('login_checkYourEmail'))));
        return;
      }

      // Check if the user is active using firebase
      var userRef =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);
      var doc = await userRef.get();

      if (doc.exists) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        bool isActive = userData['is_active'] ?? false;
        bool firstTime = userData['first_time'] ?? false;

        if (isActive) {
          _updateMessagingToken();
          if (firstTime) {
            // The user is new so we navigate them to set their profile information and send the screen to do the process
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) =>
                    TopicsScreen(userId: user.uid, screenID: 1)));
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'first_time': false,
            });
          } else {
            // The user is active
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => MainScreen(
                      userEmail: user.email!,
                    )));
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'isOnline': true,
              'lastSeen': lastSeen,
            });
          }
        } else {
          // The user is not active
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(tr('login_userNotActive'))));
        }
      } else {
        // There is not user data
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('login_userDataNotFound'))));
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = tr('login_userNotFound');
      } else if (e.code == 'wrong-password') {
        errorMessage = tr('login_invalidPassword');
      } else {
        errorMessage = tr('login_error') + ': ${e.message}';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  void _updateMessagingToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'messaging_token': token});
    }
  }

  // Function to submit the login form
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      //_showMathChallengeDialog(); // Challenge Math questions
      _login();
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Separar el nombre y el apellido
        List<String> nameParts = user.displayName?.split(' ') ?? [];
        String firstName = nameParts.isNotEmpty ? nameParts.first : '';
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // Datos del usuario
        Map<String, dynamic> userData = {
          'first_name': firstName,
          'last_name': lastName,
          'email': user.email!,
          'imageUrl': user.photoURL ?? '',
          'first_time': true,
          'join_date': DateTime.now().toUtc().toIso8601String(),
          'is_active': true,
        };

        // Guardar datos del usuario
        String uid = user.uid;
        await _database.child("users/$uid").set(userData);

        // Navegar a la pantalla principal
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MainScreen(
                  userEmail: user.email!,
                )));

        return user;
      }
    }
    return null;
  }

  // Future<User?> signInWithFacebook() async {
  //   final LoginResult result = await FacebookAuth.instance
  //       .login(); // Start the process of logging in with Facebook

  //   if (result.status == LoginStatus.success) {
  //     // Logged in successfully
  //     final OAuthCredential facebookAuthCredential =
  //         FacebookAuthProvider.credential(result.accessToken!.token);

  //     // Sign in with the credential
  //     final UserCredential userCredential = await FirebaseAuth.instance
  //         .signInWithCredential(facebookAuthCredential);
  //     final User? user = userCredential.user;

  //     if (user != null) {
  //       Navigator.of(context).pushReplacement(MaterialPageRoute(
  //           builder: (context) => MainScreen(userEmail: user.email!)));
  //     }
  //     return user;
  //   } else {
  //     print('The login failed with status: ${result.status}');
  //     return null;
  //   }
  // }

  // Function to get the user password from email and send it by mail
  Future<String?> getUserPassword(BuildContext context) async {
    // Variable to store the password
    String? password;

    // Display a dialog box for the user to enter their password
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('login_googleAddPassword')),
          content: TextField(
            onChanged: (value) {
              password = value;
            },
            obscureText: true, // To hide the password
            decoration: InputDecoration(hintText: tr('logingooglePassword')),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('login_googleCancel')),
              onPressed: () {
                Navigator.of(context).pop();
                password = null;
              },
            ),
            TextButton(
              child: Text(tr('login_googleConfirm')),
              onPressed: () {
                // Here you can add additional validations for the password
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return password;
  }

  // Comming soon dialog
  void showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Coming Soon"),
          content: Text("This feature will be available soon."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Math widget
  void _showMathChallengeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Don't close the dialog when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('login_mathChallengeTitle')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(tr('login_mathChallengeMessage') +
                    '${_mathChallenge.getQuestion()}'),
                TextFormField(
                  controller: _mathAnswerController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: tr('login_yourAnswer')),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('login_cancelButton')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(tr('login_confirmButton')),
              onPressed: () {
                if (_mathChallenge.checkAnswer(
                    int.tryParse(_mathAnswerController.text) ?? -1)) {
                  Navigator.of(context).pop(); // Close the dialog
                  _login(); // Continue with the login
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('login_wrongAnswer'))),
                  );
                  setState(() {
                    _mathChallenge;
                  });
                }
              },
            ),
          ],
        );
      },
    );
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
                        // signInWithFacebook().then((user) {
                        //   if (user != null) {
                        //     Navigator.of(context).pushReplacement(
                        //         MaterialPageRoute(
                        //             builder: (context) =>
                        //                 MainScreen(userEmail: user.email!)));
                        //   }
                        // });
                        showComingSoonDialog();
                      },
                      size: 40.0, // Button size
                    ),
                    SocialButton(
                      iconPath: 'assets/img/google.png',
                      onPressed: () {
                        //   // Google action
                        //   signInWithGoogle(context).then((user) {
                        //     if (user != null) {
                        //       Navigator.of(context)
                        //           .pushReplacement(MaterialPageRoute(
                        //               builder: (context) => MainScreen(
                        //                     userEmail: user.email!,
                        //                   )));
                        //     }
                        //   });
                        showComingSoonDialog();
                      },
                      size: 40.0, // Button size
                    ),
                    SocialButton(
                      iconPath: 'assets/img/apple.png',
                      onPressed: () {
                        // Apple action
                        showComingSoonDialog();
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
