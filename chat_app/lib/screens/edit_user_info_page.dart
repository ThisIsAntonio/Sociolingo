import 'dart:convert';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/main_screen.dart';

class EditUserInfoPage extends StatefulWidget {
  final User? user;
  final String userEmail;

  const EditUserInfoPage(
      {Key? key, required this.user, required this.userEmail})
      : super(key: key);

  @override
  _EditUserInfoPageState createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _birthdayController;
  DateTime? _birthday;
  String _countryCode = '';
  String? _selectedCountry;
  String? _phoneNumber = '';
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user?.firstName);
    _lastNameController = TextEditingController(text: widget.user?.lastName);
    _bioController = TextEditingController(text: widget.user?.bio ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.user?.phoneNumber);
    _emailController = TextEditingController(text: widget.user?.email);
    _passwordController = TextEditingController(); // No pre-fill for password
    _birthday = widget.user?.birthday;
    _selectedCountry = widget.user?.country;
    _birthdayController = TextEditingController(
      text: widget.user?.birthday != null
          ? DateFormat('yyyy-MM-dd').format(widget.user!.birthday!)
          : '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    var url = Uri.parse('http://10.0.2.2:3000/updateUserInfo');
    String? base64Image;
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    Map<String, dynamic> body = {
      'email': _emailController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'bio': _bioController.text,
      'phone_number': _countryCode + _phoneNumberController.text,
      'birthday':
          _birthday != null ? DateFormat('yyyy-MM-dd').format(_birthday!) : '',
      'country': _selectedCountry,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
      if (base64Image != null) 'profile_picture_base64': base64Image,
    };

    try {
      var response = await http.put(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User info updated successfully')));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                MainScreen(userEmail: _emailController.text)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update user info')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to the server: $e')));
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name')),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name')),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 20), // Separator (20 pixels height)
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
                  controller: _birthdayController,
                  decoration: const InputDecoration(
                      labelText: 'Birthday', hintText: 'YYYY-MM-DD'),
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
                ListTile(
                  title: Text(_selectedCountry ?? 'No country selected'),
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
                TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText:
                            'New Password (leave blank to keep the current)')),
                const SizedBox(height: 20), // Separator (20 pixels height)
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
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
                    child: Text(
                        _imageFile != null ? 'Change Image' : 'Pick Image')),
                const SizedBox(height: 20), // Separator (20 pixels height)
                ElevatedButton(
                    onPressed: _updateUserInfo,
                    child: const Text('Save Changes')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
