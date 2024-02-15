import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
//import 'package:intl/intl.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/edit_user_info_page.dart';
import 'package:chat_app/main.dart';

class UserInfoPage extends StatefulWidget {
  final String userEmail;

  const UserInfoPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  User? _user;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    languageChangeStreamController.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://serverchat2.onrender.com/userInfo?email=${widget.userEmail}'), // Adjust the URL for your environment //localhost is 100.20.92.101:300
      );
      // Print the response status code
      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Received user info: $data");
        setState(() {
          _user = User.fromJson(data);

          imageUrl = data['imageUrl'] as String?;
          print("Image URL: $imageUrl");
        });
      } else {
        print('Failed to load user info, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
  }

  Widget _userImageWidget() {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Option to handle errors, such as showing a default image
          return _defaultUserImageWidget();
        },
      );
    } else {
      // If there is no image URL, show a default image
      return _defaultUserImageWidget();
    }
  }

  Widget _defaultUserImageWidget() {
    // Method to display a default image
    return Image.asset(
      'assets/img/photo.jpg',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(), // To hide the back button.
        title: Column(
          mainAxisSize:
              MainAxisSize.max, // To occupy the minimum space necessary.
          mainAxisAlignment:
              MainAxisAlignment.center, // Center vertically on the AppBar.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Stretch the children along the crossed axis.
          children: [
            Text(
              tr('userInfo_title'),
              textAlign: TextAlign.start, // Center the text.
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true, // Ensures the title is centered in the AppBar.
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: Colors.white70, // Line color.
                    thickness: 2, // Line thickness.
                  ),
                  const SizedBox(height: 20), // Separator (20 pixel height)
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
                            Text(tr('userInfo_friends') +
                                ': 0'), // Static value for now
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Separator (40 pixels height)
                  Text(tr('userInfo_emailLabel') + '${_user!.email}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_phoneLabel') +
                      '${_user!.phoneNumber ?? 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_countryLabel') + '${_user!.country}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_bioLabel') +
                      '${_user!.bio ?? 'Not provided'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_birthdayLabel') +
                      '${_user!.birthday != null ? DateFormat('yyyy-MM-dd').format(_user!.birthday!) : 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr(
                      'userInfo_InterestsLabel')), // Placeholder for relational data
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
                    child: Text(tr('userInfo_buttonEditProfile')),
                  ),
                ],
              ),
            ),
    );
  }
}
