import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/model/user.dart';
import 'package:chat_app/screens/edit_user_info_page.dart';
import 'package:chat_app/screens/friend_detail_page.dart';
import 'package:chat_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:chat_app/screens/topics_screen.dart';
import 'package:chat_app/model/language_list.dart';

class UserInfoPage extends StatefulWidget {
  final String userEmail;

  const UserInfoPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  User? _user;
  String? imageUrl;
  int _friendCount = 0;
  List<Map<String, dynamic>> _friendsData = [];
  List<String> selectedHobbies = [];
  List<Language> _selectedLanguages = [];
  String _userPreferredLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo(widget.userEmail);
    _fetchFriends();
    _fetchSelectedHobbies();
    languageChangeStreamController.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Function to fetch the user info
  Future<void> _fetchUserInfo(String userEmail) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail) // To search by the email
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        var userDoc = docSnapshot.docs.first;
        Map<String, dynamic> data = userDoc.data();
        setState(() {
          _user = User.fromJson(data);
          imageUrl = data['imageUrl'] as String?;
          if (docSnapshot.docs.isNotEmpty) {
            var userDoc = docSnapshot.docs.first;
            Map<String, dynamic> data = userDoc.data();
            _userPreferredLanguage = data['language_preference'] ?? 'en';
            _fetchUserLanguages(data['selectedLanguages'] ?? []);
          }
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user info from Firestore: $e');
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

  // Function to fetch the list of friends
  Future<void> _fetchFriends() async {
    try {
      String currentUserId = auth.FirebaseAuth.instance.currentUser!.uid;
      var friendships = await FirebaseFirestore.instance
          .collection('friendships')
          .where('users', arrayContains: currentUserId)
          .get();

      List<Map<String, dynamic>> friendsData = [];

      for (var doc in friendships.docs) {
        String friendId = (doc.data()['users'] as List)
            .firstWhere((id) => id != currentUserId);
        var friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();
        if (friendDoc.exists) {
          Map<String, dynamic> friendData = friendDoc.data()!;
          friendData['id'] = friendDoc.id;
          friendsData.add(friendData);
        }
      }

      setState(() {
        // Update the variables of the state with the new values
        _friendsData = friendsData;
        _friendCount = friendsData.length;
      });
    } catch (e) {
      print('Error fetching friends: $e');
    }
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

  // Function to navigate to the TopicsScreen
  void _navigateToTopicsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              TopicsScreen(userId: widget.userEmail, screenID: 2)),
    );
  }

  // Function to fetch the selected hobbies
  Future<void> _fetchSelectedHobbies() async {
    try {
      // Get the current user ID
      String currentUserId = auth.FirebaseAuth.instance.currentUser!.uid;

      // Get the user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // OGet the language preference
        String languagePreference =
            userData['language_preference'] ?? 'en'; // English by default

        // Check if the user has selected hobbies
        if (userData.containsKey('selectedHobbies')) {
          List<dynamic> selectedHobbiesIds = userData['selectedHobbies'];
          //print(selectedHobbiesIds);

          // List to store the selected hobbies
          List<String> hobbiesNames = [];

          // Fetch each topic
          QuerySnapshot topicsSnapshot = await FirebaseFirestore.instance
              .collection('topics_$languagePreference')
              .get();

          for (var topicDoc in topicsSnapshot.docs) {
            // Fetch hobbies within each topic
            QuerySnapshot hobbiesSnapshot =
                await topicDoc.reference.collection('hobbies').get();

            for (var hobbyDoc in hobbiesSnapshot.docs) {
              // Check if the hobby ID is in the selected hobbies
              if (selectedHobbiesIds.contains(hobbyDoc.id)) {
                Map<String, dynamic> hobbyData =
                    hobbyDoc.data() as Map<String, dynamic>;
                hobbiesNames.add(hobbyData['name']);
              }
            }
          }

          // Update the selected hobbies
          setState(() {
            selectedHobbies = hobbiesNames;
          });
        }
      }
    } catch (e) {
      print('Error fetching selected hobbies: $e');
    }
  }

  Widget _userImageWidget() {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Option to handle errors, such as showing a default image
          return _defaultUserImageWidget();
        },
      );
    } else {
      // If there is no image URL, show a default image
      return _defaultUserImageWidget();
    }
  }

  Widget _defaultUserImageWidget() {
    // Method to display a default image
    return Image.asset(
      'assets/img/photo.jpg',
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(), // To hide the back button.
        title: Column(
          mainAxisSize:
              MainAxisSize.max, // To occupy the minimum space necessary.
          mainAxisAlignment:
              MainAxisAlignment.center, // Center vertically on the AppBar.
          crossAxisAlignment: CrossAxisAlignment
              .stretch, // Stretch the children along the crossed axis.
          children: [
            Text(
              tr('userInfo_title'),
              textAlign: TextAlign.start, // Center the text.
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true, // Ensures the title is centered in the AppBar.
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: Colors.white70, // Line color.
                    thickness: 2, // Line thickness.
                  ),
                  const SizedBox(height: 20), // Separator (20 pixel height)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _userImageWidget(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_user!.firstName} ${_user!.lastName}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showFriendsList(context),
                              child: Text(
                                  tr('userInfo_friends') + ': $_friendCount'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Separator (40 pixels height)
                  Text(tr('userInfo_emailLabel') + '${_user!.email}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_phoneLabel') +
                      '${_user!.phoneNumber ?? 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_countryLabel') + '${_user!.country}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('userInfo_languagesLabel'),
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
                  Text(tr('userInfo_bioLabel') +
                      '${_user!.bio ?? 'Not provided'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(tr('userInfo_birthdayLabel') +
                      '${_user!.birthday != null ? DateFormat('yyyy-MM-dd').format(_user!.birthday!) : 'N/A'}'),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Text(
                    selectedHobbies.isNotEmpty
                        ? 'Hobbies: ${selectedHobbies.join(', ')}'
                        : tr('userInfo_noHobbies'),
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20), // Separator (20 pixels height)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _navigateToTopicsScreen,
                          child: Text(tr('userInfo_buttonUpdateTopics')),
                        ),
                      ),
                      const SizedBox(width: 8), // Space between the buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditUserInfoPage(
                                      user: _user,
                                      userEmail: widget.userEmail)))
                            ..then((value) {
                              // Optional: Reload user information when returning from editing page
                              _fetchUserInfo(widget.userEmail);
                            }),
                          child: Text(tr('userInfo_buttonEditProfile')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
