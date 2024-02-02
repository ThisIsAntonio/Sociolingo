import 'package:flutter/material.dart';
import 'user_info_page.dart';
import 'friend_suggestions_page.dart';
import 'friend_requests_page.dart';
import 'chat_page.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  final String userEmail;

  const MainScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      UserInfoPage(userEmail: widget.userEmail),
      FriendSuggestionsPage(),
      FriendRequestsPage(),
      ChatPage(),
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize
              .min, // Ensures that the Row takes up the minimum space necessary
          children: [
            Image.asset(
              'lib/img/logo.png', // rute of your image
              fit: BoxFit.contain,
              height: 20.0, // Adjust the height as needed
            ),
            const SizedBox(width: 8.0), // Space between logo and text
            const Text('SocioLingo Chat'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Suggestions'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red, // Selected Icon color
        unselectedItemColor: Colors.grey, // Unselected Icon color
        backgroundColor:
            Colors.blue, // Background color of the BottomNavigationBar
      ),
    );
  }
}
