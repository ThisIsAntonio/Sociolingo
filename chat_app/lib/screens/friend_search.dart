import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FriendSearch extends StatefulWidget {
  @override
  _FriendSearchPage createState() => _FriendSearchPage();
}

class _FriendSearchPage extends State<FriendSearch> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? _currentUserName;
  Map<String, bool> requestSent = {};
  Map<String, String> pendingRequestIds = {};
  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _fetchAllUsers();
    loadPendingRequests();
  }

  Future<void> _fetchCurrentUserName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = docSnapshot.data();
      if (userData != null) {
        setState(() {
          _currentUserName = userData['first_name'];
        });
      }
    }
  }

  Future<void> _fetchAllUsers() async {
    final querySnapshot = await firestore.collection('users').get();
    final docs = querySnapshot.docs;
    docs.removeWhere((doc) => doc.id == currentUserId);
    setState(() {
      allUsers = docs;
      filteredUsers = docs;
    });
  }

  Future<void> loadPendingRequests() async {
    var sentRequests = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: currentUserId)
        .get();
    for (var doc in sentRequests.docs) {
      requestSent[doc['to']] = true;
      pendingRequestIds[doc['to']] = doc.id;
    }

    var receivedRequests = await firestore
        .collection('friend_requests')
        .where('to', isEqualTo: currentUserId)
        .get();
    for (var doc in receivedRequests.docs) {
      pendingRequestIds[doc['from']] = doc.id;
    }
  }

  void sendPushNotification(String message, String toUserToken, String title,
      String senderName) async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('sendPushNotification');
    try {
      final resp = await callable.call(<String, dynamic>{
        'message': message,
        'token': toUserToken,
        'title': title,
        'senderName': senderName,
      });
      print('Notification sent successfully: ${resp.data}');
    } on FirebaseFunctionsException catch (e) {
      print('Error sending notification: ${e.code} - ${e.message}');
    }
  }

  Future<void> sendFriendRequest(String friendId) async {
    var docRef = await firestore.collection('friend_requests').add({
      'from': currentUserId,
      'to': friendId,
      'status': 'pending',
    });
    setState(() {
      requestSent[friendId] = true;
      pendingRequestIds[friendId] = docRef.id;
    });

    String recipientToken = await getRecipientToken(friendId);

    if (recipientToken.isNotEmpty) {
      String senderName = _currentUserName ?? "Someone";
      sendPushNotification(tr('friendRequests_requestsFrom') + senderName,
          recipientToken, "Request", tr('friendRequests_requestsTitle'));
    }
  }

  Future<void> cancelFriendRequest(String friendId) async {
    if (pendingRequestIds.containsKey(friendId)) {
      await firestore
          .collection('friend_requests')
          .doc(pendingRequestIds[friendId])
          .delete();
      setState(() {
        requestSent.remove(friendId);
        pendingRequestIds.remove(friendId);
      });
    }

    DocumentSnapshot senderDoc =
        await firestore.collection('users').doc(currentUserId).get();

    Map<String, dynamic> userData =
        senderDoc.data() as Map<String, dynamic>? ?? {};

    String senderName = userData['first_name'] ?? "Someone";

    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('sendFriendNotification');
    try {
      await callable.call({
        'toUserId': friendId,
        'fromUserName': senderName,
        'title': "Friend Request",
      });
      print("Notification sent successfully");
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<String> getRecipientToken(String userId) async {
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
    return userData?['messaging_token'] ?? '';
  }

  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final userData = user.data() as Map<String, dynamic>;
        final firstName = (userData['first_name'] as String).toLowerCase();
        final lastName = (userData['last_name'] as String).toLowerCase();
        final email = (userData['email'] as String).toLowerCase();
        return firstName.contains(searchTerm) ||
            lastName.contains(searchTerm) ||
            email.contains(searchTerm);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (name) {
                _onSearchChanged();
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                var data = filteredUsers[index].data() as Map<String, dynamic>;
                var userId = filteredUsers[index].id;
                bool isRequestAlreadySent = requestSent[userId] ?? false;

                return ListTile(
                  leading: data['imageUrl'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(data['imageUrl']),
                        )
                      : CircleAvatar(child: Icon(Icons.person)),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['first_name']} ${data['last_name']}'),
                      Text(
                        data['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12, // Smaller font size for email
                          color: Colors.grey, // Grey color for email
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.account_box),
                        onPressed: () => showUserProfile(context, data, userId),
                      ),
                      IconButton(
                        icon: isRequestAlreadySent
                            ? Icon(Icons.check)
                            : Icon(Icons.add),
                        onPressed: isRequestAlreadySent
                            ? () => cancelFriendRequest(userId)
                            : () => sendFriendRequest(userId),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showUserProfile(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    bool isRequestAlreadySent = requestSent[userId] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${userData['first_name']} ${userData['last_name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              userData['imageUrl'] != null
                  ? Image.network(userData['imageUrl'], width: 100, height: 100)
                  : SizedBox(height: 100),
              Text('Bio: ${userData['bio']}'),
              Text('Country: ${userData['country']}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('friendSuggestions_closeButton')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Icon(isRequestAlreadySent ? Icons.check : Icons.add),
              onPressed: isRequestAlreadySent
                  ? null
                  : () {
                      sendFriendRequest(userId);
                      Navigator.of(context).pop();
                    },
            ),
          ],
        );
      },
    );
  }
}
