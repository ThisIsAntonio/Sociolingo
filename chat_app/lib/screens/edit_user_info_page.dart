import 'package:flutter/material.dart';
import 'package:chat_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chat_app/screens/main_screen.dart';

class EditUserInfoPage extends StatefulWidget {
  final User? user;
  final String? userEmail;

  const EditUserInfoPage({Key? key, this.user, required this.userEmail})
      : super(key: key);

  @override
  _EditUserInfoPageState createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with current user info
    _usernameController = TextEditingController(text: widget.user?.username);
    _bioController = TextEditingController(text: widget.user?.bio);
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo(
      String userEmail, String username, String bio) async {
    var url = Uri.parse('http://10.0.2.2:3000/updateUserInfo');
    try {
      var response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': widget.user!.email, 'username': username, 'bio': bio}),
      );

      if (response.statusCode == 200) {
        // If the update is successful, show a snackbar and navigate to the MainScreen
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User info updated successfully')));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                MainScreen(userEmail: userEmail))); // Adjust as necessary
      } else {
        // Error handling
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update user info')));
      }
    } catch (e) {
      // Error handling for server connection issues
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to the server')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateUserInfo(widget.user!.email,
                        _usernameController.text, _bioController.text);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
