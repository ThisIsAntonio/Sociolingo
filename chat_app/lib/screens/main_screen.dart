import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/user_info_page.dart';
import 'package:chat_app/screens/topics_page.dart';
import 'package:chat_app/screens/friend_requests_page.dart';
import 'package:chat_app/screens/chat_page.dart';
import 'package:chat_app/screens/settings_page.dart';

class MainScreen extends StatefulWidget {
  final String userEmail;

  const MainScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Build the selected page based on the current index
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return UserInfoPage(userEmail: widget.userEmail);
      case 1:
        return TopicsPage();
      case 2:
        return FriendRequestsPage();
      case 3:
        return ChatPage();
      case 4:
        return SettingsPage();
      default:
        return UserInfoPage(userEmail: widget.userEmail); // Fallback page
    }
  }

  // Update the selected index when tapping on a navigation item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The leading widget is empty to hide the back button
        leading: Container(),
        // App title that is localized
        title: Text('SocioLingo'),
      ),
      // The body is the currently selected page
      body: _buildPage(),
      // Bottom navigation bar to switch between pages
      bottomNavigationBar: BottomNavigationBar(
        // Navigation bar items with localized labels
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: tr('mainScreen_profileLabel'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: tr('mainScreen_topicsLabel'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: tr('mainScreen_RequestsLabel'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: tr('mainScreen_chatLabel'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: tr('mainScreen_settingsLabel'),
          ),
        ],
        // Current selected index of the navigation bar
        currentIndex: _selectedIndex,
        // Callback when tapping on a navigation item
        onTap: _onItemTapped,
        // Styling for the navigation bar
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.lightBlue,
      ),
    );
  }
}
