import 'package:flutter/material.dart';
import 'package:chat_app/screens/friendSuggestionsGrid.dart';
import 'package:chat_app/screens/friendRequestsList.dart';
import 'package:easy_localization/easy_localization.dart';

class FriendRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
      ),
      body: Column(
        children: [
          Text(
            tr('friendRequests_requestsTitle'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FriendRequestsList(), // Superior part for friend requests
          ),
          Divider(),
          const SizedBox(height: 20),
          Text(
            tr('friendRequests_suggestionsTitle'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                FriendSuggestionsGrid(), // Inferior part for friend suggestions
          ),
        ],
      ),
    );
  }
}
