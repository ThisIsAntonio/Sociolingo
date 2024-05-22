import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UsersWithHobbyPage extends StatefulWidget {
  final String hobbyId;
  final String hobbyName;

  const UsersWithHobbyPage(
      {Key? key, required this.hobbyId, required this.hobbyName})
      : super(key: key);

  @override
  _UsersWithHobbyPageState createState() => _UsersWithHobbyPageState();
}

class _UsersWithHobbyPageState extends State<UsersWithHobbyPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, bool> requestSent = {};
  Map<String, String> pendingRequestIds = {};
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
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

  // Function to get the recipient's FCM token
  Future<String> getRecipientToken(String userId) async {
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
    return userData?['messaging_token'] ?? '';
  }

  // Function to get the ID's of all friends and the current user
  Future<Set<String>> getFriendsAndCurrentUserIds() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    Set<String> friendsAndCurrentUserIds = {currentUserId};

    // Add the confirm friends to the list
    QuerySnapshot friendships = await FirebaseFirestore.instance
        .collection('friendships')
        .where('users', arrayContains: currentUserId)
        .get();
    for (var doc in friendships.docs) {
      friendsAndCurrentUserIds.addAll(List<String>.from(doc['users']));
    }

    return friendsAndCurrentUserIds;
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

  // Function to send a push notification
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double titleSize = screenWidth > 600 ? 28 : 24;
    int crossAxisCount =
        screenWidth > 1600 // <==== Next step is try to do it without a if
            ? 8
            : screenWidth > 1400
                ? 7
                : screenWidth > 1200
                    ? 6
                    : screenWidth > 1000
                        ? 5
                        : screenWidth > 800
                            ? 4
                            : screenWidth > 600
                                ? 3
                                : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.hobbyName}',
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Set<String>>(
        future: getFriendsAndCurrentUserIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(tr('userHobbies_noData')));
          }

          Set<String> excludedIds = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text("userHobbies_noData"));
                }

                List<DocumentSnapshot> usersWithHobby =
                    snapshot.data!.docs.where((userDoc) {
                  Map<String, dynamic> userData =
                      userDoc.data() as Map<String, dynamic>;
                  List<dynamic> userHobbiesIds =
                      userData['selectedHobbies'] ?? [];
                  // check if the user has the hobby and is not in the exclude list
                  return userHobbiesIds.contains(widget.hobbyId) &&
                      !excludedIds.contains(userDoc.id);
                }).toList();

                // Show a grid of users
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                  ),
                  itemCount: usersWithHobby.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> userData =
                        usersWithHobby[index].data() as Map<String, dynamic>;
                    String userId = usersWithHobby[index].id;
                    bool isRequestAlreadySent = requestSent[userId] ?? false;
                    // show user info
                    return GestureDetector(
                      onTap: () => showUserProfile(context, userData, userId),
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage: userData['imageUrl'] != null
                                  ? NetworkImage(userData['imageUrl'])
                                  : null,
                              radius: 40,
                              child: userData['imageUrl'] == null
                                  ? Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            SizedBox(height: 8),
                            Text(
                                "${userData['first_name']} ${userData['last_name']}"),
                            Text(userData['country'] ?? 'Unknown'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: isRequestAlreadySent
                                      ? Icon(Icons.check)
                                      : Icon(Icons.person_add),
                                  onPressed: isRequestAlreadySent
                                      ? null
                                      : () {
                                          sendFriendRequest(userId);
                                        },
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel),
                                  onPressed: isRequestAlreadySent
                                      ? () {
                                          cancelFriendRequest(userId);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              });
        },
      ),
    );
  }
}
