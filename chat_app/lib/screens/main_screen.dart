import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/user_info_page.dart';
import 'package:chat_app/screens/topics_page.dart';
import 'package:chat_app/screens/friend_requests_page.dart';
import 'package:chat_app/screens/chat_page.dart';
import 'package:chat_app/screens/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  final String userEmail;
  final int? returnScreen;

  const MainScreen({Key? key, required this.userEmail, this.returnScreen})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _selectedIndex;
  String lastSeen = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.returnScreen ?? 0;
    WidgetsBinding.instance.addObserver(this);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Check if the message has a notification and show it
      if (message.notification != null) {
        final snackBar = SnackBar(
          content: Text(
              message.notification!.body ?? "mainScreen_haveAnewNotification"),
          action: SnackBarAction(
            label: '>',
            onPressed: () {
              _navigateToScreen(message.notification!.title);
            },
          ),
        );

        // Show the snackbar
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      if (state == AppLifecycleState.paused) {
        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isOnline': false,
          'lastSeen': lastSeen,
        });
      } else if (state == AppLifecycleState.resumed) {
        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isOnline': true,
        });
      }
    }
  }

  void _navigateToScreen(String? title) {
    int newIndex;
    switch (title) {
      case 'Chat':
        newIndex = 0;
        break;
      case 'Request':
        newIndex = 2;
        break;
      default:
        return; // Do nothing if the title doesn't match
    }

    if (mounted) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  // Build the selected page based on the current index
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return ChatPage(); // Main Page
      case 1:
        return TopicsPage();
      case 2:
        return FriendRequestsPage();
      case 3:
        return UserInfoPage(userEmail: widget.userEmail);
      case 4:
        return SettingsPage(userEmail: widget.userEmail);
      default:
        return ChatPage(); // Fallback page
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
          // Chat Page
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: tr('mainScreen_chatLabel'),
          ),
          // Topics Page
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: tr('mainScreen_topicsLabel'),
          ),
          // Friend Requests Page
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: tr('mainScreen_RequestsLabel'),
          ),
          // User Info Page
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: tr('mainScreen_profileLabel'),
          ),
          // Settings Page
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
