import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_app/screens/login_screen.dart';

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
  //String _countryCode = '';
  String _phoneNumber = '';
  String _password = '';
  final String _bio = '';
  Country? _selectedCountry;
  XFile? _imageFile;
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Sends data to the backend for registration
  void _register() async {
    var url = Uri.parse(
        'https://serverchat2.onrender.com/register'); // Adjust the URL for your environment //localhost is 100.20.92.101:300
    try {
      // Prepare the request
      var request = http.MultipartRequest('POST', url)
        ..fields['first_name'] = _firstName
        ..fields['last_name'] = _lastName
        ..fields['email'] = _email
        ..fields['phone_number'] = _phoneNumber
        ..fields['password'] = _password
        ..fields['country'] = _selectedCountry?.name ?? ''
        ..fields['birthday'] =
            _birthday != null ? DateFormat('yyyy-MM-dd').format(_birthday!) : ''
        ..fields['bio'] = _bio;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'profile_picture', _imageFile!.path));
      }

      // Prints the information being sent for debugging
      print('Sending registration data: ${request.fields}');
      if (_imageFile != null) {
        print('Sending image: ${_imageFile!.path}');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Print the response status code
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 201) {
        // Successful registration
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('register_registerAccepted'))));
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        // Failure to register user
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('register_registerFailed'))));
      }
    } catch (e) {
      // Failed to connect to server
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('register_errorConnectingServer'))));
      print('Exception caught: $e');
    }
  }

// Method to handle form submission
  void _submit() {
    // Check if form is valid
    if (_formKey.currentState?.validate() ?? false) {
      // Save password from text field
      _password = _passwordController.text;
      // Save form fields
      _formKey.currentState?.save();
      // Call the register method
      _register();

      // Clear text fields
      _passwordController.clear();
      _confirmPasswordController.clear();
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
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                // Title and subtitle
                Text(
                  tr('register_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tr('register_subtitle'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),
                // First name
                TextFormField(
                  decoration:
                      InputDecoration(labelText: tr('register_labelFirstName')),
                  onSaved: (value) => _firstName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? tr('register_firstName') : null,
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Last Name
                TextFormField(
                  decoration:
                      InputDecoration(labelText: tr('register_labeLastName')),
                  onSaved: (value) => _lastName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? tr('register_lastName') : null,
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Birthday
                TextFormField(
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
                      return 'Please enter your birthday';
                    }
                    try {
                      final date = DateFormat('yyyy-MM-dd').parseStrict(value);
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
                      _birthday = DateFormat('yyyy-MM-dd').parseStrict(value);
                    }
                  },
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Email
                TextFormField(
                  decoration:
                      InputDecoration(labelText: tr('register_labelEmail')),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? tr('register_errorEmail')
                      : null,
                ),
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
                            return 'Please enter your phone number';
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration:
                      InputDecoration(labelText: tr('register_labelPassword')),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return tr('register_errorPasswordLong');
                    }
                    return null;
                  },
                ),
                // Confirm password
                TextFormField(
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

                const SizedBox(height: 20), // Separator (20 pixels height)
                // Country
                ListTile(
                  title: Text(
                      _selectedCountry?.name ?? tr('register_countryError')),
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
                if (_imageFile != null) Image.file(File(_imageFile!.path)),
                // Image
                OutlinedButton(
                  onPressed: _pickImage,
                  child: Text(tr('register_pickProfileImage')),
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Bio
                TextFormField(
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
                const SizedBox(height: 20), // Separator (20 pixels height)
                // Button
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(tr('register_buttonRegister')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
