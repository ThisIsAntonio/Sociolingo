import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/edit_user_info_page.dart';

class UserInfoPage extends StatefulWidget {
  final String userEmail;

  const UserInfoPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/userInfo?email=${widget.userEmail}'),
      );
      // Print the response status code
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Received user info: $data");
        setState(() {
          _user = User.fromJson(data);
        });
      } else {
        print('Failed to load user info, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Widget _userImageWidget() {
    if (_user != null &&
        _user!.imageBase64 != null &&
        _user!.imageBase64!.isNotEmpty) {
      // If a user image exists, display the decoded image
      return Image.memory(
        base64Decode(_user!.imageBase64!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      // If there is no user image, show a default image
      return Image.asset(
        'lib/img/photo.jpg', // Asegúrate de que la ruta de acceso sea correcta
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _userImageWidget(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_user!.firstName} ${_user!.lastName}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Friends: 0'), // Static value for now
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Separator (40 pixels height)
                  Text('Email: ${_user!.email}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text('Phone: ${_user!.phoneNumber ?? 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text('Country: ${_user!.country}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text('Bio: ${_user!.bio ?? 'Not provided'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(
                      'Birthday: ${_user!.birthday != null ? DateFormat('yyyy-MM-dd').format(_user!.birthday!) : 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  const Text(
                      'Interests, Languages, etc. will go here'), // Placeholder for relational data
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditUserInfoPage(
                                user: _user, userEmail: widget.userEmail)))
                      ..then((value) {
                        // Optional: Reload user information when returning from editing page
                        _fetchUserInfo();
                      }),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
