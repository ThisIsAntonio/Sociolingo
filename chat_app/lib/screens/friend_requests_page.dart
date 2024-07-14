import 'package:flutter/material.dart';
import 'package:chat_app/screens/friendSuggestionsGrid.dart';
import 'package:chat_app/screens/friendRequestsList.dart';
import 'package:chat_app/screens/friend_search.dart';
import 'package:easy_localization/easy_localization.dart';

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

  final List<String> _titles = [
    tr('friendRequests_requestsTitle'),
    tr('friendRequests_suggestionsTitle'),
    tr('friendRequests_searchTitle'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: Text(_titles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: tr('friendRequests_requestsTitle'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: tr('friendRequests_suggestionsTitle'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: tr('friendRequests_searchTitle'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
