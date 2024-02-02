import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chat_app/model/user.dart';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _user = User.fromJson(data);
        });
      } else {
        // Manejar respuestas no exitosas
        print('Failed to load user info, status code: ${response.statusCode}');
      }
    } catch (e) {
      // Capturar errores durante la solicitud o el procesamiento de la respuesta
      print('Error fetching user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _user == null
          ? CircularProgressIndicator()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Email: ${_user!.email}'),
                  Text('Username: ${_user!.username}'),
                  Text('Bio: ${_user!.bio}'),
                ],
              ),
            ),
    );
  }
}
