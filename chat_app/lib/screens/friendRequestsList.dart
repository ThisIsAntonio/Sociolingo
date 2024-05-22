import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getPendingFriendRequests() {
    String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get user details from Firebase by UserID and display them in a list tile
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    var userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data();
  }

  // Respond to friend request (accept or reject)
  Future<void> respondToFriendRequest(String requestId, bool accepted) async {
    // Check if the request exists before trying to update it
    var requestDoc =
        await _firestore.collection('friend_requests').doc(requestId).get();
    var requestData = requestDoc.data();
    if (requestData == null) return;

    // Update the status of the friend request
    if (accepted) {
      await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Add a new friendship document for both users
      String currentUserId = _auth.currentUser!.uid;
      String friendUserId = requestData['from'];
      await _firestore.collection('friendships').add({
        'users': [currentUserId, friendUserId],
        'created_at': FieldValue.serverTimestamp(),
        'is_friend': true,
      });
    } else {
      // Update the status of the friend request as rejected
      await _firestore.collection('friend_requests').doc(requestId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double fontSize = screenWidth > 600 ? 18 : 16;
    double columnWidth =
        screenWidth > 600 ? screenWidth * 0.5 : screenWidth * 0.90;

    return StreamBuilder<QuerySnapshot>(
      stream: getPendingFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var requests = snapshot.data!.docs;
          return Center(
            child: SizedBox(
              width: columnWidth,
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  var request = requests[index];
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: getUserDetails(request['from']),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                              ConnectionState.done &&
                          userSnapshot.data != null) {
                        var userData = userSnapshot.data!;
                        return ListTile(
                          leading: userData['imageUrl'] != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(userData['imageUrl']),
                                )
                              : CircleAvatar(child: Icon(Icons.person)),
                          title: Text(
                            '${userData['first_name']} ${userData['last_name']}',
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () =>
                                    respondToFriendRequest(request.id, true),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () =>
                                    respondToFriendRequest(request.id, false),
                              ),
                            ],
                          ),
                        );
                      }
                      return CircularProgressIndicator();
                    },
                  );
                },
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
