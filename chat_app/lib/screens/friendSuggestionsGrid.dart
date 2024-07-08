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
  List<DocumentSnapshot> userSuggestions = [];
  bool suggestionsLoaded = false;

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

  // Function to load user suggestions
  Future<void> loadSuggestions() async {
    if (!suggestionsLoaded) {
      List<String> excludedIds = await loadPendingRequests();
      var usersQuery = await firestore.collection('users').get();
      userSuggestions = usersQuery.docs;
      userSuggestions.removeWhere(
          (doc) => excludedIds.contains(doc.id) || doc.id == currentUserId);
      userSuggestions.shuffle();
      userSuggestions = userSuggestions.take(10).toList();
      setState(() {
        suggestionsLoaded = true;
      });
    }
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

  // Function to get the recipient's FCM token
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (userData['imageUrl'] != null &&
                    userData['imageUrl'].isNotEmpty)
                  Image.network(
                    userData['imageUrl'],
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons
                          .error); // Mostrar un icono de error si la imagen no se puede cargar
                    },
                  )
                else
                  SizedBox(height: 100, child: Icon(Icons.person, size: 40)),
                Text('Bio: ${userData['bio']}'),
                Text('Country: ${userData['country']}'),
              ],
            ),
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
        screenWidth > 800 ? screenWidth * 0.8 : screenWidth * 1;

    return Scaffold(
      body: FutureBuilder<void>(
        future: loadSuggestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Container(
              width: columnWidth,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: crossAxisCount > 6
                        ? .5
                        : crossAxisCount > 2
                            ? .65
                            : 1),
                itemCount: userSuggestions.length,
                itemBuilder: (context, index) {
                  var user =
                      userSuggestions[index].data() as Map<String, dynamic>;
                  var userId = userSuggestions[index].id;
                  bool isRequestSent = requestSent[userId] ?? false;

                  return GestureDetector(
                    onTap: () => showUserProfile(context, user, userId),
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (user['imageUrl'] != null &&
                              user['imageUrl'].isNotEmpty)
                            CircleAvatar(
                              backgroundImage: NetworkImage(user['imageUrl']),
                              radius: 30,
                            )
                          else
                            CircleAvatar(
                              child: Icon(Icons.person, size: 40),
                              radius: 30,
                            ),
                          SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              user['first_name'] ?? 'Unknown',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              user['last_name'] ?? 'Unknown',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              user['country'] ?? 'Unknown',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.0,
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
                                onPressed: () => cancelFriendRequest(userId),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
