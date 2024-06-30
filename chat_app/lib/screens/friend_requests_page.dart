import 'package:flutter/material.dart';
import 'package:chat_app/screens/friendSuggestionsGrid.dart';
import 'package:chat_app/screens/friendRequestsList.dart';
import 'package:chat_app/screens/friend_search.dart';



//import 'package:easy_localization/easy_localization.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPage createState() => _FriendRequestsPage();
}

class _FriendRequestsPage extends State<FriendRequestsPage> {

  int currentPageIndex = 0;

final List<Widget> pages = [
    FriendRequestsList(),
    FriendSuggestionsGrid(),
    FriendSearch(),

  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
                leading: Container(),

        actions: <Widget> [
            ElevatedButton(
            onPressed: () {
             setState((){
              currentPageIndex = 0;
             });
            },
            child: Text('Requests')
              ),
              ElevatedButton(
            onPressed: () {
               setState((){
              currentPageIndex = 1;
             });
            },
            child: Text('Suggestions')
              ),
              
                  ElevatedButton(
            onPressed: () {
              setState((){
              currentPageIndex = 2;
             });
            },
            child: Text('Search')
              ),
              ]
      ),
     body:
     Expanded(
            child: pages[currentPageIndex],
          ),
    );
    
  }
}

