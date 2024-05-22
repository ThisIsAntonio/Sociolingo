import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FriendSuggestionsGrid extends StatefulWidget {
  @override
  _FriendSuggestionsGridState createState() => _FriendSuggestionsGridState();
}

class _FriendSuggestionsGridState extends State<FriendSuggestionsGrid> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, bool> requestSent = {};
  Map<String, String> pendingRequestIds = {};
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    loadPendingRequests();
    _fetchCurrentUserName();
  }

  // Function to fetch the current user's name
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

  // Function to load pending requests from Firestore database
  Future<List<String>> loadPendingRequests() async {
    // Get the ID's friends
    List<String> friendsIds = [
      currentUserId
    ]; // include the current user ID in the list of friends

    var friendships = await firestore
        .collection('friendships')
        .where('users', arrayContains: currentUserId)
        .get();
    for (var doc in friendships.docs) {
      var users = List<String>.from(doc['users']);
      friendsIds.addAll(users.where((userId) => userId != currentUserId));
    }

    // Get the ID's sent and received friend requests
    var sentRequests = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: currentUserId)
        .get();
    for (var doc in sentRequests.docs) {
      requestSent[doc['to']] = true;
      pendingRequestIds[doc['to']] = doc.id;
    }

    // Get the ID's received friend requests that are not yet responded to
    var receivedRequests = await firestore
        .collection('friend_requests')
        .where('to', isEqualTo: currentUserId)
        .get();
    for (var doc in receivedRequests.docs) {
      pendingRequestIds[doc['from']] = doc.id;
    }

    return friendsIds;
  }

  // Function to send a friend request
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

    // Obtain the recipient's FCM token
    String recipientToken = await getRecipientToken(friendId);

    // Now call the function to send the push notification
    if (recipientToken.isNotEmpty) {
      String senderName = _currentUserName ?? "Someone";
      sendPushNotification(tr('friendRequests_requestsFrom') + senderName,
          recipientToken, "Request", tr('friendRequests_requestsTitle'));
    }
  }

  // Function to cancel a friend request
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

    // Get the current user from the database
    DocumentSnapshot senderDoc =
        await firestore.collection('users').doc(currentUserId).get();

    // Try to cast the data
    Map<String, dynamic> userData =
        senderDoc.data() as Map<String, dynamic>? ?? {};

    String senderName = userData['first_name'] ?? "Someone";

    // Call the Cloud Function to send the notification
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

  void sendPushNotification(String message, String toUserToken, String title,
      String senderName) async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('sendPushNotification');
    try {
      final resp = await callable.call(<String, dynamic>{
        'message': message,
        'token': toUserToken,
        'title': title, // Pass the title to the Cloud Function
        'senderName': senderName, // Pass the sender's name for personalization
      });
      print('Notification sent successfully: ${resp.data}');
    } on FirebaseFunctionsException catch (e) {
      print('Error sending notification: ${e.code} - ${e.message}');
    }
  }

  Future<String> getRecipientToken(String userId) async {
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
    return userData?['messaging_token'] ?? '';
  }

  // Function to show a user profile
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    int crossAxisCount = screenWidth > 1300
        ? 10
        : screenWidth > 1200
            ? 9
            : screenWidth > 1100
                ? 8
                : screenWidth > 1000
                    ? 7
                    : screenWidth > 900
                        ? 6
                        : screenWidth > 800
                            ? 5
                            : screenWidth > 700
                                ? 4
                                : screenWidth > 600
                                    ? 3
                                    : 2;
    double columnWidth =
        screenWidth > 800 ? screenWidth * 0.80 : screenWidth * 0.95;

    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: loadPendingRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          List<String> excludedIds = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              List<DocumentSnapshot> users = snapshot.data!.docs;
              // Filter the user that are not friends and that are not the current user.
              users.removeWhere((doc) =>
                  excludedIds.contains(doc.id) || doc.id == currentUserId);

              // Shufler user and show only 10 random users.
              users.shuffle();
              users = users.take(10).toList();

              return Center(
                child: Container(
                  width: columnWidth,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: crossAxisCount == 2 ? 1.2 : .55),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index].data() as Map<String, dynamic>;
                      var userId = users[index].id;
                      bool isRequestSent = requestSent[userId] ?? false;

                      return GestureDetector(
                        onTap: () => showUserProfile(context, user, userId),
                        child: Card(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: user['imageUrl'] != null
                                      ? NetworkImage(user['imageUrl'])
                                      : null,
                                  radius: 30,
                                  child: user['imageUrl'] == null
                                      ? Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${user['first_name']}\n${user['last_name']}",
                                  textAlign: TextAlign.center,
                                ),
                                Text(user['country'] ?? 'Unknown'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: isRequestSent
                                          ? Icon(Icons.check)
                                          : Icon(Icons.add),
                                      onPressed: () => isRequestSent
                                          ? null
                                          : sendFriendRequest(userId),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel),
                                      onPressed: () =>
                                          cancelFriendRequest(userId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
