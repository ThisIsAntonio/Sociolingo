import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/model/language_list.dart';

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
  int _friendCount = 0;
  List<Map<String, dynamic>> _friendsData = [];
  List<Language> _selectedLanguages = [];
  String _userPreferredLanguage = 'en';

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchFriendInfo();
    _checkFriendshipStatus();
    _fetchFriends();
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
        if (userDoc.docs.isNotEmpty) {
          var userDocs = userDoc.docs.first;
          Map<String, dynamic> data = userDocs.data();
          _userPreferredLanguage = data['language_preference'] ?? 'en';
          _fetchUserLanguages(data['selectedLanguages'] ?? []);
        }
      });
    }
  }

  String getLanguageName(Language language, String userPreferredLanguage) {
    switch (userPreferredLanguage) {
      case 'en':
        return language.nameInEnglish;
      case 'fr':
        return language.nameInFrench;
      case 'es':
        return language.nameInSpanish;
      default:
        return language.nameInEnglish; // Default to English
    }
  }

  Future<void> _fetchUserLanguages(List<dynamic> languageIds) async {
    List<Language> userLanguages = [];
    for (String languageId in languageIds) {
      var documentSnapshot = await FirebaseFirestore.instance
          .collection('languages')
          .doc(languageId)
          .get();
      if (documentSnapshot.exists) {
        Language language =
            Language.fromMap(documentSnapshot.data()!, documentSnapshot.id);
        userLanguages.add(language);
      }
    }
    setState(() {
      _selectedLanguages = userLanguages;
    });
  }

  // Add a new function to get the friend's user ID from their email
  Future<String?> _getUserIdFromEmail(String email) async {
    final usersQuerySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (usersQuerySnapshot.docs.isNotEmpty) {
      return usersQuerySnapshot.docs.first.id;
    }
    return null;
  }

  // Function to fetch the list of friends
  Future<void> _fetchFriends() async {
    try {
      final friendId = await _getUserIdFromEmail(widget.email);
      if (friendId == null) {
        print("Friend user ID not found");
        return;
      }

      var friendships = await _firestore
          .collection('friendships')
          .where('users', arrayContains: friendId)
          .get();

      List<Map<String, dynamic>> friendsData = [];

      for (var doc in friendships.docs) {
        String _friendId =
            (doc.data()['users'] as List).firstWhere((id) => id != friendId);
        var friendDoc =
            await _firestore.collection('users').doc(_friendId).get();
        if (friendDoc.exists) {
          Map<String, dynamic> friendData = friendDoc.data()!;
          friendData['id'] = friendDoc.id;
          friendsData.add(friendData);
        }
      }

      setState(() {
        _friendsData = friendsData;
        _friendCount = friendsData.length;
      });
    } catch (e) {
      print('Error fetching friends: $e');
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

  // Function to show the list of friends in a dialog box
  void _showFriendsList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('userInfo_popUpTitle')),
          content: SingleChildScrollView(
            child: ListBody(
              children: _friendsData
                  .map((friendData) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(friendData[
                                  'imageUrl'] ??
                              'https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/photo.jpg?alt=media&token=b370db11-d8de-495d-93da-e7b10aabd841'),
                        ),
                        title: Text(
                            '${friendData['first_name']} ${friendData['last_name']}'),
                        onTap: () {
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FriendDetailsPage(
                                      email: friendData[
                                          'email']))); // Go to FriendDetailsPage
                        },
                      ))
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('userInfo_closeButton')),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('friendInfo_text1')),
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
                            SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => _showFriendsList(context),
                              child: Text(
                                  tr('userInfo_friends') + ': $_friendCount'),
                            ),
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
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('friendInfo_languagesLabel'),
                      ),
                      Wrap(
                        spacing: 8.0, // Espacio horizontal entre los chips
                        children: _selectedLanguages
                            .map((language) => Chip(
                                  label: Text(getLanguageName(
                                      language, _userPreferredLanguage)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('friendInfo_emailLabel') + ' ${_friend!.email}'),
                  const SizedBox(height: 20),
                  Text(tr('friendInfo_phoneLabel') +
                      '${_friend!.phoneNumber ?? 'N/A'}'),
                  const SizedBox(height: 20),
                  Text(tr('friendInfo_countryLabel') + '${_friend!.country}'),
                  const SizedBox(height: 20),
                  Text(tr('friendInfo_bioLabel') + '${_friend!.bio ?? 'N/A'}'),
                  const SizedBox(height: 20),
                  Text(tr('friendInfo_birthdayLabel') +
                      '${_friend!.birthday != null ? DateFormat('yyyy-MM-dd').format(_friend!.birthday!) : 'N/A'}'),
                  const SizedBox(height: 20),
                  Text(
                    _friendHobbies.isNotEmpty
                        ? tr('friendInfo_hobbiesLabel') +
                            '${_friendHobbies.join(', ')}'
                        : tr('userInfo_noHobbies'),
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
}
