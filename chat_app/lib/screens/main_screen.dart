import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/user_info_page.dart';
import 'package:chat_app/screens/topics_page.dart';
import 'package:chat_app/screens/friend_requests_page.dart';
import 'package:chat_app/screens/chat_page.dart';
import 'package:chat_app/screens/settings_page.dart';
import 'package:chat_app/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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
  User? currentUser;
  late int _selectedIndex;
  bool _isCollapsed = false;
  bool _userCollapsed = false;
  String? imageUrl;
  String lastSeen = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adjustMenuForScreenSize();
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _adjustMenuForScreenSize();
  }

  void _adjustMenuForScreenSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    setState(() {
      if (isLargeScreen) {
        // When expanding to large screen, respect user's choice
        _isCollapsed = _userCollapsed;
      } else {
        // When reducing to small screen, always collapse
        _isCollapsed = false;
      }
    });
  }

  void _fetchUserDetails() async {
    String? email = auth.FirebaseAuth.instance.currentUser?.email;

    if (email != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        var userDoc1 = userDoc.docs.first;
        Map<String, dynamic> data = userDoc1.data();
        setState(() {
          currentUser = User.fromJson(data);
          imageUrl = data['imageUrl'] as String?;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = auth.FirebaseAuth.instance.currentUser?.uid;
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

  Widget _userImageWidget(double imageSize) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Option to handle errors, such as showing a default image
          return _defaultUserImageWidget(imageSize);
        },
      );
    } else {
      // If there is no image URL, show a default image
      return _defaultUserImageWidget(imageSize);
    }
  }

  Widget _defaultUserImageWidget(double imageSize) {
    // Method to display a default image
    return Image.asset(
      'assets/img/photo.jpg',
      width: imageSize,
      height: imageSize,
      fit: BoxFit.cover,
    );
  }

  Widget _buildDrawer() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _isCollapsed
                ? DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black12
                          : Colors.white12,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: CircleAvatar(
                        radius: 20,
                        child: ClipOval(
                          child: _userImageWidget(30),
                        ),
                      ),
                    ),
                  )
                : UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black12
                          : Colors.white12,
                    ),
                    currentAccountPicture: CircleAvatar(
                      child: ClipOval(
                        child: _userImageWidget(80),
                      ),
                    ),
                    accountName: Text(
                      '${currentUser?.firstName ?? ''} ${currentUser?.lastName ?? ''}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    accountEmail: Text(
                      currentUser?.email ?? '',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
            ListTile(
              selected: _selectedIndex == 0,
              selectedTileColor: Colors.grey,
              selectedColor: Colors.red,
              title: _isCollapsed ? null : Text(tr('mainScreen_chatLabel')),
              leading: Icon(Icons.chat),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              selected: _selectedIndex == 1,
              selectedTileColor: Colors.grey,
              selectedColor: Colors.red,
              title: _isCollapsed ? null : Text(tr('mainScreen_topicsLabel')),
              leading: Icon(Icons.people),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              selected: _selectedIndex == 2,
              selectedTileColor: Colors.grey,
              selectedColor: Colors.red,
              title: _isCollapsed ? null : Text(tr('mainScreen_RequestsLabel')),
              leading: Icon(Icons.mail),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              selected: _selectedIndex == 3,
              selectedTileColor: Colors.grey,
              selectedColor: Colors.red,
              title: _isCollapsed ? null : Text(tr('mainScreen_profileLabel')),
              leading: Icon(Icons.account_circle),
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              selected: _selectedIndex == 4,
              selectedTileColor: Colors.grey,
              selectedColor: Colors.red,
              title: _isCollapsed ? null : Text(tr('mainScreen_settingsLabel')),
              leading: Icon(Icons.settings),
              onTap: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavBar() {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: tr('mainScreen_chatLabel'),
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
          icon: Icon(Icons.account_circle),
          label: tr('mainScreen_profileLabel'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: tr('mainScreen_settingsLabel'),
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double titleSize = screenWidth > 600 ? 28 : 24;
    bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('SocioLingo',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold)),
        leading: isLargeScreen
            ? IconButton(
                icon: Icon(_isCollapsed ? Icons.menu_open : Icons.menu),
                onPressed: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                    _userCollapsed = _isCollapsed;
                  });
                },
              )
            : null,
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: _isCollapsed ? 60 : 250,
              child: _buildDrawer(),
            ),
          Expanded(
            child: _buildPage(),
          ),
        ],
      ),
      bottomNavigationBar: isLargeScreen ? null : _buildMobileNavBar(),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       // The leading widget is empty to hide the back button
  //       leading: Container(),
  //       // App title that is localized
  //       title: Text('SocioLingo'),
  //     ),
  //     // The body is the currently selected page
  //     body: _buildPage(),
  //     // Bottom navigation bar to switch between pages
  //     bottomNavigationBar: BottomNavigationBar(
  //       // Navigation bar items with localized labels
  //       items: <BottomNavigationBarItem>[
  //         // Chat Page
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.chat),
  //           label: tr('mainScreen_chatLabel'),
  //         ),
  //         // Topics Page
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.people),
  //           label: tr('mainScreen_topicsLabel'),
  //         ),
  //         // Friend Requests Page
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.mail),
  //           label: tr('mainScreen_RequestsLabel'),
  //         ),
  //         // User Info Page
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.account_circle),
  //           label: tr('mainScreen_profileLabel'),
  //         ),
  //         // Settings Page
  //         BottomNavigationBarItem(
  //           icon: Icon(Icons.settings),
  //           label: tr('mainScreen_settingsLabel'),
  //         ),
  //       ],
  //       // Current selected index of the navigation bar
  //       currentIndex: _selectedIndex,
  //       // Callback when tapping on a navigation item
  //       onTap: _onItemTapped,
  //       // Styling for the navigation bar
  //       selectedItemColor: Colors.red,
  //       unselectedItemColor: Colors.grey,
  //       backgroundColor: Colors.lightBlue,
  //     ),
  //   );
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
