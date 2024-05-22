import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:chat_app/model/language_list.dart';

class EditUserInfoPage extends StatefulWidget {
  // Properties for receiving user data and email
  final User? user;
  final String userEmail;

  // Constructor for initializing the widget
  const EditUserInfoPage(
      {Key? key, required this.user, required this.userEmail})
      : super(key: key);

  // Method to create the state for this widget
  @override
  _EditUserInfoPageState createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  // GlobalKey for managing the Form state
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for managing form fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _birthdayController;
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Variables to store user data and selected values
  DateTime? _birthday;
  String? _country = '';

  // Variable to store selected image file
  XFile? _imageFile;

  // ImagePicker instance for picking images
  final ImagePicker _picker = ImagePicker();

  List<Language> _selectedLanguages = [];
  List<Language> _allLanguages = [];

  @override
  void initState() {
    // Call the initState method of the superclass
    super.initState();
    _loadLanguages();

    // Initialize text editing controllers and other variables
    _firstNameController = TextEditingController(text: widget.user?.firstName);
    _lastNameController = TextEditingController(text: widget.user?.lastName);
    _bioController = TextEditingController(text: widget.user?.bio ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.user?.phoneNumber);
    _emailController = TextEditingController(text: widget.user?.email);
    _passwordController = TextEditingController(); // No pre-fill for password
    _birthday = widget.user?.birthday;
    _country = widget.user?.country;

    // Initialize birthday controller with formatted date if available
    _birthdayController = TextEditingController(
      text: widget.user?.birthday != null
          ? DateFormat('yyyy-MM-dd').format(widget.user!.birthday!)
          : '',
    );
  }

  @override
  void dispose() {
    // Dispose all text editing controllers to free up resources
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _confirmPasswordController.clear();

    // Call the dispose method of the superclass
    super.dispose();
  }

  Future<void> _attemptUpdateUserInfo() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl;
      if (_imageFile != null) {
        // If there is an image selected, first upload the image and then update the user information.
        imageUrl = await _uploadImageToFirebase(_imageFile!);
        _updateUserInfo(imageUrl);
      } else {
        // If there is no new image selected, it simply updates the user information.
        _updateUserInfo();
      }
    } else {
      // If the form is invalid, display a message or perform some action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('editUserInfo_validationFailed'))),
      );
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

  // Method to update user information
  Future<void> _updateUserInfo([String? imageUrl]) async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, dynamic> updateData = {
          if (_firstNameController.text != widget.user?.firstName)
            'first_name': _firstNameController.text,
          if (_lastNameController.text != widget.user?.lastName)
            'last_name': _lastNameController.text,
          if (_bioController.text != widget.user?.bio)
            'bio': _bioController.text,
          if (_phoneNumberController.text != widget.user?.phoneNumber)
            'phone_number': _phoneNumberController.text,
          if (_emailController.text != widget.user?.email)
            'email': _emailController.text,
          if (_birthday != widget.user?.birthday)
            'birthday': _birthday != null
                ? DateFormat('yyyy-MM-dd').format(_birthday!)
                : null,
          if ('selectedLanguages' != widget.user?.selectedLanguages)
            'selectedLanguages':
                _selectedLanguages.map((lang) => lang.id).toList(),
          if (_country != widget.user?.country) 'country': _country,
          if (imageUrl != null) 'imageUrl': imageUrl,
        };

        // Update Firestore
        String? uid = auth.FirebaseAuth.instance.currentUser?.uid;
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updateData);

        // Update password if necessary
        if (_passwordController.text.isNotEmpty) {
          await auth.FirebaseAuth.instance.currentUser
              ?.updatePassword(_passwordController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('editUserInfo_updateSuccessfully'))));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                MainScreen(userEmail: widget.userEmail, returnScreen: 3)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('editUserInfo_updateFailed') + ' $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image; // Asegúrate de que se establece _imageFile
      });
      print("Image Path: ${_imageFile?.path}");
    }
  }

  Future<String> _uploadImageToFirebase(XFile image) async {
    String filePath =
        'profile_pictures/${widget.userEmail}/${DateTime.now()}.png';
    await firebase_storage.FirebaseStorage.instance
        .ref(filePath)
        .putFile(File(image.path));
    return await firebase_storage.FirebaseStorage.instance
        .ref(filePath)
        .getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double padding = screenWidth > 800 ? 30.0 : 16.0;
    double titleSize = screenWidth > 800 ? 28 : 24;
    double inputWidth =
        screenWidth > 800 ? screenWidth * 0.4 : screenWidth * 0.8;
    double fontSize = screenWidth > 800 ? 18 : 16;

    return Scaffold(
      appBar: AppBar(
          leading: Container(), // To hide the back button.
          title: Text(
            tr('editUserInfo_title'),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          )),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // First Name
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                          labelText: tr('edifUserInfo_labelFirstName')),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Last Name
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                          labelText: tr('editUserInfo_labelLastName')),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Email
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: tr('editUserInfo_labelEmail')),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Phone number
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
                              labelText: tr('editUserInfo_labelPhoneNumber'),
                              hintText: tr('editUserInfo_phoneNumber'),
                              hintStyle: TextStyle(
                                  color: Colors.grey), // Placeholder Style
                            ),
                            keyboardType: TextInputType.phone,
                            controller: _phoneNumberController,
                            validator: (value) {
                              String pattern = r'^\+\d+\s\d+$';
                              RegExp regExp = RegExp(pattern);
                              if (value == null || value.isEmpty) {
                                return tr('editUserInfo_enterPhoneNumber');
                              } else if (!regExp.hasMatch(value)) {
                                return tr('editUserInfo_invalidFormat');
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
                  // Birthday
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _birthdayController,
                      decoration: InputDecoration(
                          labelText: tr('editUserInfo_labelBirthday'),
                          hintText: 'YYYY-MM-DD'),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
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
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Country
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: ListTile(
                      title: Text(
                        _country ?? tr('editUserInfo_noCountrySelected'),
                        style: TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          onSelect: (Country country) {
                            setState(() {
                              _country = country.name;
                              //_countryCode = '+${country.phoneCode}';
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Password
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                          labelText: tr('editUserInfo_newPassword')),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isNotEmpty && value.length < 6) {
                          return tr('editUserInfo_errorPasswordLong');
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
                          labelText: tr('editUserInfo_confirmPassword')),
                      obscureText: true,
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return tr('editUserInfo_confirmPasswordNoMatch');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  // Bio
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: tr('editUserInfo_labelBio'),
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
                    child: OutlinedButton(
                        onPressed: _pickImage,
                        child: Text(_imageFile != null
                            ? tr('editUserInfo_changeImage')
                            : tr('editUserInfo_pickImage'))),
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
                        style:
                            TextStyle(color: Colors.white, fontSize: fontSize),
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      buttonIcon: Icon(
                        Icons.language, // Icon to display in the button
                        color: Colors.white, // Icon color
                      ),
                      itemsTextStyle: TextStyle(color: Colors.white),
                      selectedItemsTextStyle:
                          TextStyle(color: Colors.lightBlue),
                      cancelText: Text(tr('editUserInfo_buttonCancel'),
                          style: TextStyle(
                              color: Colors.white, fontSize: fontSize)),
                      confirmText: Text(tr('editUserInfo_confirmButton'),
                          style: TextStyle(
                              color: Colors.white, fontSize: fontSize)),
                    ),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: inputWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => MainScreen(
                                        userEmail: widget.userEmail,
                                        returnScreen: 3)));
                          },
                          child: Text(
                            tr('editUserInfo_buttonCancel'),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _attemptUpdateUserInfo,
                          child: Text(
                            tr('editUserInfo_buttonUpdate'),
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ],
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
}
