import 'package:flutter/material.dart';
import 'package:chat_app/screens/friendSuggestionsGrid.dart';
import 'package:chat_app/screens/friendRequestsList.dart';
import 'package:chat_app/screens/friend_search.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPage createState() => _FriendRequestsPage();
}

class _FriendRequestsPage extends State<FriendRequestsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    FriendRequestsList(),
    FriendSuggestionsGrid(),
    FriendSearch(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Suggestions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
