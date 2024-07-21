import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/chat_window.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? selectedFriendId;

// Function to get the list of friends from Firestore database
  Future<bool> _isFriendWith(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    // print('Current User ID: $currentUserId, Checking Friend ID: $friendId');

    final friendships = await _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUserId)
        .get();

    // Check if friendId is in any of the friendship documents
    bool isFriend = friendships.docs.any((doc) {
      List<dynamic> users = doc['users'];
      return users.contains(friendId);
    });

    // print('Is Friend: $isFriend');
    return isFriend;
  }

  // Function to get the list of unread messages for a specific user
  Future<int> countUnreadMessages(String chatId) async {
    var snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('receiverId',
            isEqualTo: _auth.currentUser!.uid) // Asegúrate de esto
        .get();

    return snapshot.docs.length;
  }

  // Function to show the list of friends from Firestore database
  void _showFriendsList() async {
    var currentUser = _auth.currentUser;
    var friendshipsSnapshot = await _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUser!.uid)
        .get();

    List<Map<String, dynamic>> friends = [];
    for (var doc in friendshipsSnapshot.docs) {
      List<dynamic> users = doc['users'];
      String friendId = users.firstWhere((userId) => userId != currentUser.uid);
      var userDoc = await _firestore.collection('users').doc(friendId).get();
      var userData = userDoc.data();
      if (userData != null) {
        friends.add({
          'id': friendId,
          ...userData,
        });
      }
    }

    // Show the list of friends on UI using setState method
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('chatPage_text1')),
          content: SingleChildScrollView(
            child: ListBody(
              children: friends
                  .map((friend) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(friend['imageUrl'] ??
                              'https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/photo.jpg?alt=media&token=b370db11-d8de-495d-93da-e7b10aabd841'),
                        ),
                        title: Text(
                            '${friend['first_name']} ${friend['last_name']}'),
                        onTap: () {
                          Navigator.pop(context); // Close the dialog
                          setState(() {
                            selectedFriendId = friend['id'];
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 800;
    double titleSize = isLargeScreen ? 28 : 24;
    double subtitleSize = isLargeScreen ? 18 : 14;

    return Scaffold(
      appBar: !isLargeScreen && selectedFriendId != null
          ? null
          : AppBar(
              leading: Container(),
              title: Text(
                tr('chatPage_title'),
                style:
                    TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _showFriendsList,
                ),
              ],
            ),
      body: Row(
        children: [
          if (isLargeScreen || selectedFriendId == null)
            Container(
              width: isLargeScreen ? screenWidth * 0.35 : screenWidth,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('friendships')
                    .where('users', arrayContains: _auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, friendshipSnapshot) {
                  if (!friendshipSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var friendships = friendshipSnapshot.data!.docs
                      .map((doc) => (doc.data()
                          as Map<String, dynamic>)['users'] as List<dynamic>)
                      .toList();

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .where('participants',
                            arrayContains: _auth.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var chats = snapshot.data!.docs;
                      return ListView(
                        children: chats.map<Widget>((chat) {
                          var friendId = (chat['participants'] as List)
                              .firstWhere((id) => id != _auth.currentUser!.uid);
                          //print('Chat with Friend ID: $friendId');

                          if (!friendships
                              .any((users) => users.contains(friendId))) {
                            return Container(); // Do not show if not friends
                          }

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(friendId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(); // Do not show anything while loading
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Container();
                              }

                              var friend =
                                  snapshot.data!.data() as Map<String, dynamic>;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      friend['imageUrl'] ??
                                          'default_image_path'),
                                ),
                                title: Text(
                                  "${friend['first_name']} ${friend['last_name']}",
                                  style: TextStyle(fontSize: subtitleSize),
                                ),
                                subtitle: FutureBuilder<int>(
                                  future: countUnreadMessages(chat.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Loading...");
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data! > 0) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(chat['lastMessage'] ??
                                              "No messages"),
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${snapshot.data}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Text(
                                          chat['lastMessage'] ?? "No messages");
                                    }
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedFriendId = friendId;
                                  });
                                  if (!isLargeScreen) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatWindow(
                                          key: ValueKey(selectedFriendId),
                                          friendId: selectedFriendId!,
                                          isLargeScreen: isLargeScreen,
                                        ),
                                      ),
                                    ).then((_) {
                                      setState(() {
                                        selectedFriendId = null;
                                      });
                                    });
                                  }
                                },
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          if (selectedFriendId != null)
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 300,
                ),
                child: Container(
                  child: ChatWindow(
                    key: ValueKey(selectedFriendId),
                    friendId: selectedFriendId!,
                    isLargeScreen: isLargeScreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
