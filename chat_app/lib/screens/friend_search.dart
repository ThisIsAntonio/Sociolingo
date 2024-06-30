import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'friendSuggestionsGrid.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:cloud_functions/cloud_functions.dart';



class FriendSearch extends StatefulWidget {

_FriendSearchPage createState() => _FriendSearchPage();

}

class _FriendSearchPage extends State<FriendSearch>{

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
String? _currentUserName;
 Map<String, bool> requestSent = {};
 Map<String, String> pendingRequestIds = {};
 Future<List<DocumentSnapshot>>? searchResults;
   late Key _futureBuilderKey = UniqueKey();

@override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
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

    Future<String> getRecipientToken(String userId) async {
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
    return userData?['messaging_token'] ?? '';
  }

Future<List<DocumentSnapshot>> searchUsers(String searchTerm) async {
    var name = searchTerm.split(" ");
    QuerySnapshot<Map<String, dynamic>> searchQuery;
    if (name.length == 10 && name[1] != ""){
        searchQuery = await firestore 
      .collection('users')
      .where('first_name', isGreaterThanOrEqualTo: name[0])
      //.where('first_name', isLessThan: searchTerm)     
      .where('last_name', isGreaterThanOrEqualTo: name[1])


      //.where('first_name', isLessThan: searchTerm)     
      .limit(15)
      .get();

    }else{
     searchQuery = await firestore 
      .collection('users')
      .where('first_name', isGreaterThanOrEqualTo: name[0])
      //.where('first_name', isLessThan: searchTerm)     
      .limit(15)
      .get();
    }

      setState(() {
      _futureBuilderKey = UniqueKey();
    });
    return searchQuery.docs;
    
}

void _refreshData(String name) {
    setState(() {
      searchResults = searchUsers(name);
    });
  }




Widget build(BuildContext context) {
return Scaffold(
      
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (name) {
                searchUsers(name);   
              },
              onSubmitted: _refreshData,
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
            child:  
            FutureBuilder<List<DocumentSnapshot>>(
              key: _futureBuilderKey,
              future: searchResults,
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No results found.'));
              }


              List<DocumentSnapshot> docs = snapshot.data!;

              docs.removeWhere((doc) =>  doc.id == currentUserId);

              return ListView.builder(
                itemCount: docs.length, 
                itemBuilder: (context, index) {
                  //bool userRemoved = false;
                  

                  var data = docs[index].data() as Map<String, dynamic>;
                  var userId = docs[index].id;
                  //bool isRequestSent = requestSent[userId] ?? false;
                  
                  return ListTile(
                      leading: data['imageUrl'] != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(data['imageUrl']),
                            )
                         : CircleAvatar(child: Icon(Icons.person)), 
                      title: Text(
                          '${data['first_name']} ${data['last_name']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () =>
                               sendFriendRequest(userId),
                               
                          ),
                          IconButton(
                            icon: Icon(Icons.account_box),
                            onPressed: () =>
                            showUserProfile(context, data, userId),
                                //Text("false")
                          ),
                        ],
                      ),
                    );
                },
              );
            },
            ), 
          ),
        ],
      ),
    );
  }

}