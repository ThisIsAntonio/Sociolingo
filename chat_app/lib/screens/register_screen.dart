import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

  // Sends data to the backend for registration
  void _register() async {
    var url = Uri.parse(
        'http://10.0.2.2:3000/register'); // Ajusta la URL para tu entorno
    try {
      // Prepara el request
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
            SnackBar(content: Text('User registered successfully')));
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        // Failure to register user
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to register user')));
      }
    } catch (e) {
      // Failed to connect to server
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to the server')));
      print('Exception caught: $e');
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _register();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('lib/img/logo.png', fit: BoxFit.contain, height: 20.0),
            const SizedBox(width: 8.0),
            const Text('SocioLingo Chat - Register'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onSaved: (value) => _firstName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your first name' : null,
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onSaved: (value) => _lastName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your last name' : null,
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                  controller: _birthdayController,
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
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
                        return 'You must be at least 18 years old';
                      }

                      return null; // If the date is valid
                    } catch (e) {
                      return 'Please enter a valid date format (YYYY-MM-DD)';
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
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value ?? '',
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Please enter a valid email'
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
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
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
                            return 'Please enter a valid phone number format: +[country code] [number]';
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
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) => _password = value ?? '',
                  validator: (value) => value!.isEmpty || value.length < 6
                      ? 'Password must be at least 6 characters long'
                      : null,
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                ListTile(
                  title: Text(_selectedCountry?.name ?? 'No country selected'),
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
                OutlinedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Profile Image'),
                ),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio (Optional)',
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
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
