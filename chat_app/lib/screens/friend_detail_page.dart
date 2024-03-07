import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:easy_localization/easy_localization.dart';

class FriendDetailsPage extends StatefulWidget {
  final String
      email; // We use the email of the friend to fetch the friend's information

  const FriendDetailsPage({Key? key, required this.email}) : super(key: key);

  @override
  _FriendDetailsPageState createState() => _FriendDetailsPageState();
}

class _FriendDetailsPageState extends State<FriendDetailsPage> {
  User? _friend;
  String? imageUrl;
  bool _isFriend = false;
  String? _friendshipDocId;
  List<String> _friendHobbies = [];

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchFriendInfo();
    _checkFriendshipStatus();
  }

  // FetchFriendInfo from Firebase Firestore and set the state with the data of the friend
  Future<void> _fetchFriendInfo() async {
    final userDoc = await _firestore
        .collection('users')
        .where('email', isEqualTo: widget.email)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final userData = userDoc.docs.first.data();
      setState(() {
        _friend = User.fromJson(userData);
        imageUrl = userData['imageUrl'];
        final selectedHobbiesIds =
            List<String>.from(userData['selectedHobbies'] ?? []);
        _fetchFriendHobbiesNames(selectedHobbiesIds);
      });
    }
  }

  // CheckFriendshipStatus from Firebase Firestore to know if the current logged in user is friends with the friend
  Future<void> _checkFriendshipStatus() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final friendshipQuery = await _firestore
        .collection('friendships')
        .where('users', arrayContainsAny: [currentUserId, widget.email]).get();

    if (friendshipQuery.docs.isNotEmpty) {
      // Found a friendship document
      setState(() {
        _isFriend = true;
        _friendshipDocId = friendshipQuery.docs.first.id;
      });
    } else {
      setState(() {
        _isFriend = false;
      });
    }
  }

  // CheckFriendshipStatus from Firebase Firestore to know if the current logged in user is friends with the friend
  Future<void> _toggleFriendship() async {
    if (_isFriend) {
      // If they are currently friends, delete the friendship
      if (_friendshipDocId != null) {
        await _firestore
            .collection('friendships')
            .doc(_friendshipDocId!)
            .delete();
      }
    } else {
      // If they are not friends, send a friend request or directly add as friend
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        var docRef = await _firestore.collection('friendships').add({
          'users': [currentUserId, widget.email],
          'created_at': FieldValue.serverTimestamp(),
        });
        _friendshipDocId = docRef.id;
      }
    }
    _checkFriendshipStatus(); // Refresh friendship status after toggling
  }

  // FetchFriendHobbiesNames from Firebase Firestore and set the state with the data of the friend's hobby names
  Future<void> _fetchFriendHobbiesNames(List<String> friendHobbiesIds) async {
    // Get the current user preference language
    String currentUserId = auth.FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    String languagePreference = 'en'; // English by default
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      languagePreference = userData['language_preference'] ?? 'en';
    }

    List<String> hobbiesNames = [];

    // Search for the friend's hobbies in the topics collection and get their names
    QuerySnapshot topicsSnapshot = await FirebaseFirestore.instance
        .collection('topics_$languagePreference')
        .get();

    for (var topicDoc in topicsSnapshot.docs) {
      QuerySnapshot hobbiesSnapshot =
          await topicDoc.reference.collection('hobbies').get();
      for (var hobbyDoc in hobbiesSnapshot.docs) {
        if (friendHobbiesIds.contains(hobbyDoc.id)) {
          Map<String, dynamic> hobbyData =
              hobbyDoc.data() as Map<String, dynamic>;
          hobbiesNames.add(hobbyData['name']);
        }
      }
    }

    setState(() {
      // Update the info with the new information
      _friendHobbies = hobbiesNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('friendDetails_text1')),
      ),
      body: _friend == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl!)
                            : AssetImage('assets/img/photo.jpg')
                                as ImageProvider,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_friend!.firstName} ${_friend!.lastName}',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            _isFriend
                                ? IconButton(
                                    icon: Icon(Icons.delete_forever),
                                    onPressed: _toggleFriendship,
                                  )
                                : IconButton(
                                    icon: Icon(Icons.person_add),
                                    onPressed: _toggleFriendship,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text('Email: ${_friend!.email}'),
                  SizedBox(height: 20),
                  Text('Phone: ${_friend!.phoneNumber ?? 'N/A'}'),
                  SizedBox(height: 20),
                  Text('Country: ${_friend!.country}'),
                  SizedBox(height: 20),
                  Text('Bio: ${_friend!.bio ?? 'N/A'}'),
                  SizedBox(height: 20),
                  Text(
                      'Birthday: ${_friend!.birthday != null ? DateFormat('yyyy-MM-dd').format(_friend!.birthday!) : 'N/A'}'),
                  SizedBox(height: 20),
                  Text(
                    _friendHobbies.isNotEmpty
                        ? 'Hobbies: ${_friendHobbies.join(', ')}'
                        : tr('userInfo_noHobbies'),
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
}
