import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/main_screen.dart';

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
  String _countryCode = '';
  String? _selectedCountry;

  // Variable to store selected image file
  XFile? _imageFile;
  String? _imageUrl;

  // ImagePicker instance for picking images
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    // Call the initState method of the superclass
    super.initState();

    // Initialize text editing controllers and other variables
    _firstNameController = TextEditingController(text: widget.user?.firstName);
    _lastNameController = TextEditingController(text: widget.user?.lastName);
    _bioController = TextEditingController(text: widget.user?.bio ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.user?.phoneNumber);
    _emailController = TextEditingController(text: widget.user?.email);
    _passwordController = TextEditingController(); // No pre-fill for password
    _birthday = widget.user?.birthday;
    _selectedCountry = widget.user?.country;

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
    print('all dispose');
  }

  Future<void> _attemptUpdateUserInfo() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        // If there is an image selected, first upload the image and then update the user information.
        await _uploadImageToFirebase(_imageFile!).then((_) {
          _updateUserInfo();
        });
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

  // Method to update user information
  Future<void> _updateUserInfo() async {
    // Adjust the URL for your environment
    // For example, if running locally, change 'serverchat2.onrender.com' to 'localhost' or your local IP address
    var url = Uri.parse('https://serverchat2.onrender.com/updateUserInfo');

    // Create the request body with user information
    Map<String, dynamic> body = {
      'email': _emailController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'bio': _bioController.text,
      'phone_number': _countryCode +
          _phoneNumberController.text, // Combine country code with phone number
      'birthday': _birthday != null
          ? DateFormat('yyyy-MM-dd').format(_birthday!)
          : '', // Format birthday if available
      'country': _selectedCountry,
      'imageUrl': _imageUrl, // Include profile picture if available
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text, // Include password if not empty
    };

    try {
      // Send PUT request to update user info
      var response = await http.put(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      // Handle response based on status code
      if (response.statusCode == 200) {
        // Show success message and navigate to main screen if successful
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('editUserInfo_updateSuccessfully'))));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                MainScreen(userEmail: _emailController.text)));
      } else {
        // Show error message if request failed
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('editUserInfo_updateFailed'))));
      }
    } catch (e) {
      // Show error message if there's a connection error
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('editUserInfo_errorConnecting') + '$e')));
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Upload the image to Firebase Storage and get the URL
      _uploadImageToFirebase(image);
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    try {
      // Defines the name of the file in storage, it could be unique per user
      String fileName =
          "user_images/${widget.userEmail}/${DateTime.now().millisecondsSinceEpoch.toString()}";

      // Upload the file to Firebase Storage
      firebase_storage.UploadTask task = firebase_storage
          .FirebaseStorage.instance
          .ref(fileName)
          .putFile(File(image.path));

      // Wait for the upload to complete
      await task.whenComplete(() {});

      // Get the download URL
      var imageUrl = await firebase_storage.FirebaseStorage.instance
          .ref(fileName)
          .getDownloadURL();

      // Update the state variable with the new image
      if (!mounted) return;
      setState(() {
        _imageUrl = imageUrl;
      });
      print("Image URL: $imageUrl");
      print("_Image URL: $_imageUrl");
    } catch (e) {
      print("Error uploading image to Firebase Storage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: Container(), // To hide the back button.
          title: Text(tr('editUserInfo_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // First Name
                TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                        labelText: tr('edifUserInfo_labelFirstName'))),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Last Name
                TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                        labelText: tr('editUserInfo_labelLastName'))),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Email
                TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: tr('editUserInfo_labelEmail'))),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Phone number
                Row(
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Birthday
                TextFormField(
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Country
                ListTile(
                  title: Text(
                      _selectedCountry ?? tr('editUserInfo_noCountrySelected')),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      onSelect: (Country country) {
                        setState(() {
                          _selectedCountry = country.name;
                          _countryCode = '+${country.phoneCode}';
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Password
                TextFormField(
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
                // Confirm password
                TextFormField(
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Bio
                TextFormField(
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                OutlinedButton(
                    onPressed: _pickImage,
                    child: Text(_imageFile != null
                        ? tr('editUserInfo_changeImage')
                        : tr('editUserInfo_pickImage'))),
                const SizedBox(height: 20), // Separator (20 pixels height)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) =>
                                MainScreen(userEmail: widget.userEmail)));
                      },
                      child: Text(tr('editUserInfo_buttonCancel')),
                    ),
                    ElevatedButton(
                      onPressed: _attemptUpdateUserInfo,
                      child: Text(tr('editUserInfo_buttonUpdate')),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
