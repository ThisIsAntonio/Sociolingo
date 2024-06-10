import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/model/MathChallenge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:chat_app/model/language_list.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/model/theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String _firstName = '';
  String _lastName = '';
  DateTime? _birthday;
  String _email = '';
  String _phoneNumber = '';
  String _password = '';
  Country? _selectedCountry;
  XFile? _imageFile;
  //String? _imageUrl = '';
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _mathChallenge = MathChallenge();
  final _mathAnswerController = TextEditingController();
  List<Language> _selectedLanguages = [];
  List<Language> _allLanguages = []; // Fill out with all languages

  bool _acceptTerms = false; // var to keep the current checkbox in false

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  // Sends data to the backend for registration
  void _register() async {
    // Initialize firebase if it is not already initialized
    if (!Firebase.apps.isNotEmpty) {
      await Firebase.initializeApp();
    }

    try {
      // Create a new instance of FirebaseAuth and use its signUp method
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      // Get the UID from the user
      String uid = userCredential.user!.uid;

      // Get the Bio info
      final String bio = _bioController.text;

      // upload the image to Firebase
      String imageUrl = await uploadImageToFirebase(_imageFile, _email);

      // Get the datetime now
      String joinDate = DateTime.now().toUtc().toIso8601String();

      // Create an Object from the user data
      Map<String, dynamic> userData = {
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
        'phone_number': _phoneNumber,
        'country': _selectedCountry?.name ?? '',
        'birthday': _birthday != null
            ? DateFormat('yyyy-MM-dd').format(_birthday!)
            : '',
        'bio': bio,
        'imageUrl': imageUrl,
        'first_time': true, // show this is the first time to the user
        'join_date': joinDate, // put the datetime now
        'is_active': true, // The user is active on the app
        'language_preference':
            'en', // Default language preference set to English
        'isOnline': true,
        'lastSeen': '',
        'selectedLanguages':
            _selectedLanguages.map((language) => language.id).toList(),
      };

      // Save the user data in Firebase Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // Comeback to the Login Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Show error messages
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('register_emailInUse'))),
        );
      } else {
        print('Failed to register user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('register_errorToRegister') + '$e')),
        );
      }
    }
  }

  Future<void> _loadLanguages() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('languages').get();
    _allLanguages = querySnapshot.docs
        .map((doc) => Language.fromMap(doc.data(), doc.id))
        .toList();
    setState(() {});
  }

// Method to handle form submission
  void _submit() {
    // Check if form is valid
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        // Error message if the user does not accept the terms
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('register_errorNotAcceptTerms'))),
        );
        return; // Stop the registration process
      }
      // Call matchChallengerDialog method
      _showMathChallengeDialog();
    }
  }

// Method to pick an image from the device's gallery
  Future<void> _pickImage() async {
    // Use ImagePicker to pick an image from the gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // Check if image is selected
    if (image != null) {
      // Update the state with the selected image file
      setState(() {
        _imageFile = image;
      });

      uploadImageToFirebase(image, _email);
    }
  }

  // Method to upload the image to Firebase
  Future<String> uploadImageToFirebase(
      XFile? imageFile, String userEmail) async {
    if (imageFile == null) return '';
    String filePath = 'profile_pictures/$userEmail/${DateTime.now()}.png';
    try {
      // Verifica la plataforma
      if (kIsWeb) {
        // Para la web
        Uint8List imageBytes = await imageFile.readAsBytes();
        await firebase_storage.FirebaseStorage.instance
            .ref(filePath)
            .putData(imageBytes);
      } else {
        // Para móviles
        await firebase_storage.FirebaseStorage.instance
            .ref(filePath)
            .putFile(File(imageFile.path));
      }

      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref(filePath)
          .getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Error uploading the image: $e");
      return '';
    }
  }

  // Math widget
  void _showMathChallengeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Don't close the dialog when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('register_mathChallengeTitle')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(tr('register_mathChallengeMessage') +
                    '${_mathChallenge.getQuestion()}'),
                TextFormField(
                  controller: _mathAnswerController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: tr('register_yourAnswer')),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('register_cancelButton')),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(tr('register_confirmButton')),
              onPressed: () {
                if (_mathChallenge.checkAnswer(
                    int.tryParse(_mathAnswerController.text) ?? -1)) {
                  //print('entro');
                  Navigator.of(context).pop(); // Close the dialog
                  // Save password from text field
                  _password = _passwordController.text;
                  // Save form fields
                  _formKey.currentState?.save();
                  _register(); // Continue with the login
                  // Clear text fields
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('register_wrongAnswer'))),
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
  void dispose() {
    // release the resource when it is no longer needed
    _bioController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double padding = screenWidth > 800 ? 30.0 : 16.0;
    double titleSize = screenWidth > 800 ? 28 : 24;
    double subtitleSize = screenWidth > 800 ? 18 : 14;
    double inputWidth = screenWidth > 800 ? screenWidth * 0.4 : screenWidth * 0.8;
    double logoSize = screenWidth > 800 ? 200 : 100;
    final themeProvider = Provider.of<ThemeProvider>(context); // Add different versions of logo for light/dark theme
    String namelogo = themeProvider.themeMode==ThemeMode.dark? "assets/img/namelogo_white.png" : "assets/img/namelogo_black.png";
    const fontColor = Color.fromARGB(255, 4, 33, 52);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        namelogo, // Update theme logos
                        width: logoSize,
                        //height: 200, 
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title and subtitle
                  Text(
                    tr('register_title'),
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('register_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: subtitleSize),
                  ),
                  const SizedBox(height: 35),
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
                  const SizedBox(height: 35),
                  // First name
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: tr('register_labelFirstName')),
                      onSaved: (value) => _firstName = value ?? '',
                      validator: (value) =>
                          value!.isEmpty ? tr('register_firstName') : null,
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Last Name
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: tr('register_labeLastName')),
                      onSaved: (value) => _lastName = value ?? '',
                      validator: (value) =>
                          value!.isEmpty ? tr('register_lastName') : null,
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Birthday
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _birthdayController,
                      decoration: InputDecoration(
                        labelText: tr('register_labelBirthday'),
                        hintText: 'YYYY-MM-DD',
                      ),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        // Hide keyboard when tapping on the field
                        FocusScope.of(context).requestFocus(FocusNode());

                        // Show DatePicker
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _birthday ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != _birthday) {
                          setState(() {
                            _birthday = picked;
                            _birthdayController.text =
                                DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('register_pleaseEnterYourBirthday');
                        }
                        try {
                          final date =
                              DateFormat('yyyy-MM-dd').parseStrict(value);
                          final today = DateTime.now();
                          int age = today.year -
                              date.year; // Make 'age' a non-final variable
                          final birthdayThisYear =
                              DateTime(today.year, date.month, date.day);

                          if (birthdayThisYear.isAfter(today)) {
                            age--; // Now 'age' can be modified
                          }

                          if (age < 18) {
                            return tr('register_errorBirthday');
                          }

                          return null; // If the date is valid
                        } catch (e) {
                          return tr('register_invalidFormatBirthday');
                        }
                      },
                      onSaved: (value) {
                        // Update _birthday with the manually entered value if necessary
                        if (value != null && value.isNotEmpty) {
                          _birthday =
                              DateFormat('yyyy-MM-dd').parseStrict(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Email
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      decoration:
                          InputDecoration(labelText: tr('register_labelEmail')),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) => _email = value ?? '',
                      validator: (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? tr('register_errorEmail')
                              : null,
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: Row(
                      children: [
                        // Button to select the country code for the phone number
                        // OutlinedButton(
                        //   onPressed: () {
                        //     showCountryPicker(
                        //       context: context,
                        //       onSelect: (Country country) {
                        //         setState(() {
                        //           _countryCode = '+${country.phoneCode}';
                        //         });
                        //       },
                        //     );
                        //   },
                        //   child: Text(_countryCode),
                        // ),
                        //const SizedBox(width: 10),
                        // Phone number
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: tr('register_labelPhoneNumber'),
                              hintText: tr('register_phoneNumber'),
                              hintStyle: TextStyle(
                                  color: Colors.grey), // Placeholder Style
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            controller: _phoneNumberController,
                            onSaved: (value) => _phoneNumber = value ?? '',
                            validator: (value) {
                              String pattern = r'^\+\d+\s\d+$';
                              RegExp regExp = RegExp(pattern);
                              if (value == null || value.isEmpty) {
                                return tr(
                                    'register_pleaseEnterYourPhoneNumber');
                              } else if (!regExp.hasMatch(value)) {
                                return tr('register_invalidFormat');
                              }
                              // You can add additional validations here if you need it
                              return null;
                            },
                            // Allows only digits, spaces and the plus sign
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\+?[0-9 ]*$')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Password
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                          labelText: tr('register_labelPassword')),
                      obscureText: true,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 6) {
                          return tr('register_errorPasswordLong');
                        }
                        return null;
                      },
                    ),
                  ),
                  // Confirm password
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                          labelText: tr('register_confirmPassword')),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('register_confirmPasswordRequired');
                        }
                        if (value != _passwordController.text) {
                          return tr('register_confirmPasswordNoMatch');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Country
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: ListTile(
                      title: Text(_selectedCountry?.name ??
                          tr('register_countryError')),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  if (_imageFile != null) Image.file(File(_imageFile!.path)),
                  // Image
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: OutlinedButton(
                      onPressed: _pickImage,
                      child: Text(tr('register_pickProfileImage')),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Bio
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: tr('register_labelBio'),
                      ),
                      maxLength:
                          255, // Sets the maximum number of characters allowed.
                      // The 'buildCounter' property allows you to customize the character counter.
                      buildCounter: (
                        BuildContext context, {
                        int? currentLength,
                        int? maxLength,
                        bool? isFocused,
                      }) {
                        return Text(
                          '${currentLength ?? 0}/${maxLength}', // Shows the updated character counter.
                          style: TextStyle(
                            color: currentLength! > maxLength!
                                ? Colors.red
                                : Colors
                                    .grey, // Change the color if the limit is exceeded.
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: MultiSelectDialogField<Language>(
                      items: _allLanguages
                          .map((language) => MultiSelectItem<Language>(
                              language, language.nameInEnglish))
                          .toList(),
                      title: Text(tr('register_labelLanguagesTitle')),
                      buttonText: Text(
                        tr('register_selectButton'),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),                  
                      onConfirm: (values) {
                        setState(() {
                          _selectedLanguages = values;
                        });
                      },
                      chipDisplay: MultiSelectChipDisplay(
                        onTap: (value) {
                          setState(() {
                            _selectedLanguages.remove(value);
                          });
                        },
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor, // Use the main color of the app
                        // color: Color.fromRGBO(108, 167, 163, 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      buttonIcon: Icon(
                        Icons.language, // Icon to display in the button
                        color:Colors.white, // Icon color
                      ),
                      itemsTextStyle: TextStyle(color: fontColor),
                      selectedItemsTextStyle:
                          TextStyle(color: Theme.of(context).primaryColor,
                          ),
                      cancelText: Text(tr('register_cancelButton'),
                          style: TextStyle(color: Theme.of(context).primaryColor)),
                      confirmText: Text(tr('register_confirmButton'),
                          style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value!;
                                });
                              },
                            ),
                            Text(
                              tr('register_AcceptTerm'),
                              style: TextStyle(fontSize: 16),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Show pop up with terms and conditions
                                _showTermsAndConditionsDialog();
                              },
                              child: Text(
                                tr('register_TermsAndConditions'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .blue, // Change the color to look like a message
                                  decoration: TextDecoration
                                      .underline, // underline the text
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Register Button
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                      //backgroundColor: Theme.of(context).primaryColor, // Background color
                      //brightness: Brightness.light;
                      backgroundColor: Color.fromRGBO(162, 245, 238, 1),
                      foregroundColor: Colors.black, // Text color
                      minimumSize: Size(double.infinity, 50), // Size of the bottom
                      ),                    
                      child: Text(tr('register_buttonRegister')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsAndConditionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('register_termsAndConditionTitle')),
          content: SingleChildScrollView(
            child: Text(
              // Terms and conditions info
              tr('register_termsAndConditionContent'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(tr('register_buttonClose')),
            ),
          ],
        );
      },
    );
  }
}
