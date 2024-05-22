import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:chat_app/model/language_list.dart';

class ChatWindow extends StatefulWidget {
  final String friendId;
  final String? chatId;
  final bool isLargeScreen;

  const ChatWindow(
      {Key? key,
      required this.friendId,
      required this.isLargeScreen,
      this.chatId})
      : super(key: key);

  @override
  _ChatWindowState createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;
  String? _friendName;
  String? _currentUserName;
  bool _isFriendOnline = false;
  String userPreferredLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    _fetchFriendDetails();
    _fetchCurrentUserName();
    fetchUserPreferredLanguage();
    if (_chatId == null) {
      _checkForExistingChat();
    }
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

  // Function to show the friend information in the appbar
  Future<void> _fetchFriendDetails() async {
    _firestore.collection('users').doc(widget.friendId).snapshots().listen(
      (doc) {
        final data = doc.data();
        if (data != null && mounted) {
          setState(() {
            _friendName = "${data['first_name']} ${data['last_name']}";
            _isFriendOnline = data['isOnline'] ?? false;
          });
        }
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  //  Function to check if the users are friends or not
  Future<bool> _areUsersFriends(String friendId) async {
    final userId = _auth.currentUser!.uid;
    final friendships = await _firestore
        .collection('friendships')
        .where('users', arrayContains: userId)
        .get();

    // Check if the user is in the 'users' array of the 'friendships' document
    return friendships.docs
        .any((doc) => List.from(doc['users']).contains(friendId));
  }

  // Function to check if the users have a chat window
  Future<void> _checkForExistingChat() async {
    final userId = _auth.currentUser!.uid;
    final friendId = widget.friendId;

    // Check if the users are friends
    bool areFriends = await _areUsersFriends(friendId);
    if (!areFriends) {
      print("The users are not friends");
      return;
    }

    // If they are friends, check if there is an existing chat between them
    final querySnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContainsAny: [userId, friendId]).get();

    for (var doc in querySnapshot.docs) {
      final participants = List.from(doc['participants']);
      if (participants.contains(userId) && participants.contains(friendId)) {
        setState(() {
          _chatId = doc.id;
        });
        return;
      }
    }

    if (_chatId == null) {
      _chatId = await _createNewChat();
    }
  }

  // Function to create a new chat between the users
  Future<String> _createNewChat() async {
    final userId = _auth.currentUser!.uid;
    final friendId = widget.friendId;
    // Agregate the new chat document with the two users and their respective data
    DocumentReference chatDocRef = await _firestore.collection('chats').add({
      'participants': [userId, friendId],
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return chatDocRef.id;
  }

// Function to send a message
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _chatId ??= await _createNewChat();

      // Add a new message to the chat document with the current user's information
      DocumentReference messageRef = _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc();
      await messageRef.set({
        'senderId': _auth.currentUser!.uid,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update the chat document with the last message and timestamp
      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the message controller after sending
      _messageController.clear();

      // Obtain the recipient's FCM token
      String recipientToken = await getRecipientToken(widget.friendId);

      // Now call the function to send the push notification
      if (recipientToken.isNotEmpty) {
        String senderName = _currentUserName ?? "Someone";
        sendPushNotification(message, recipientToken, "Chat", senderName);
      }
    }
  }

  // Function to mark messages as read
  void markMessagesAsRead(String chatId) {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isEqualTo: widget.friendId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'read': true});
      }
    });
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

  // Function to get the recipient's FCM token
  Future<String> getRecipientToken(String userId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(userId).get();
    Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
    return userData?['messaging_token'] ?? '';
  }

  Future<String> translateText(
      String text, String fromLanguage, String toLanguage) async {
    // Call the Cloud Function to translate the text
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('translateTextFunction');
    try {
      final result = await callable.call({
        'text': text,
        'fromLanguage': fromLanguage,
        'toLanguage': toLanguage,
      });

      return result.data[
          'translatedText']; // Extract the translated text from the response.
    } on FirebaseFunctionsException catch (e) {
      print('Error to call the translate function: ${e.message}');
      return text; // Return the original text if there's an error.
    }
  }

  // Function to load languages from Firestore
  Future<List<Language>> loadLanguagesFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('languages').get();

    List<Language> languages = querySnapshot.docs.map((doc) {
      return Language.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    return languages;
  }

  // Function to fetch the user's preferred language
  Future<void> fetchUserPreferredLanguage() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userPreferredLanguage = userData['language_preference'] ??
            'en'; // 'en' how default language
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatId != null) {
        markMessagesAsRead(_chatId!);
      }
    });
    return Scaffold(
      appBar: AppBar(
        leading: widget.isLargeScreen
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  // Comeback to MainScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MainScreen(userEmail: currentUserEmail)),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_friendName ?? "Chat"),
            if (_isFriendOnline)
              Text(
                "Online",
                style: TextStyle(
                  fontSize: 12,
                  //color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? Center(child: Text(tr('chatWindow_startConversation')))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData =
                              messages[index].data() as Map<String, dynamic>;
                          final isMine =
                              messageData['senderId'] == _auth.currentUser!.uid;
                          final messageText = messageData['text'];
                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isMine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  margin: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? Color.fromARGB(255, 126, 190, 137)
                                        : Colors.blue,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    messageData['text'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    left: isMine ? 0 : 8,
                                    right: isMine ? 8 : 0,
                                    bottom: 5,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      showTranslateDialog(context, messageText);
                                    },
                                    child: Text(
                                      tr('chatWindow_translateWithAI'),
                                      style: TextStyle(
                                        fontSize:
                                            12, // Smaller text size for "Translate with AI"
                                        color: Colors
                                            .grey, // Grey text to differentiate
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                        labelText: tr('chatWindow_typeAmessage')),
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to get the language preference of the current user
  Future<String> getCurrentUserLanguagePreference() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    Map<String, dynamic> userData =
        currentUserDoc.data() as Map<String, dynamic>;
    return userData['language_preference'];
  }

  // Function to get the language preference of the current user
  Future<String> getFriendLanguagePreference(String friendId) async {
    DocumentSnapshot friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .get();
    Map<String, dynamic> friendData = friendDoc.data() as Map<String, dynamic>;
    return friendData['language_preference'];
  }

  // Function to show the translation dialog box for a given message and language code
  void showTranslateDialog(BuildContext context, String textToTranslate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Asynchronously fetch the user and friend's language preferences
        return FutureBuilder<Map<String, dynamic>>(
          future: Future.wait([
            getCurrentUserLanguagePreference(),
            getFriendLanguagePreference(widget.friendId),
          ]).then((List<String> preferences) => {
                "currentUserLanguagePreference": preferences[0],
                "friendLanguagePreference": preferences[1],
              }),
          builder: (context,
              AsyncSnapshot<Map<String, dynamic>> preferencesSnapshot) {
            if (!preferencesSnapshot.hasData) {
              return AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            // Fetch the list of languages from Firestore
            return FutureBuilder<List<Language>>(
              future: loadLanguagesFromFirestore(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Language>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Language> languages = snapshot.data!;
                // Find the language objects based on the preferences
                Language currentUserLanguage = languages.firstWhere(
                  (lang) =>
                      lang.id ==
                      preferencesSnapshot
                          .data!["currentUserLanguagePreference"],
                  orElse: () => languages.first,
                );
                Language friendLanguage = languages.firstWhere(
                  (lang) =>
                      lang.id ==
                      preferencesSnapshot.data!["friendLanguagePreference"],
                  orElse: () => languages.first,
                );

                Language? selectedLanguageFrom = friendLanguage;
                Language? selectedLanguageTo = currentUserLanguage;
                String? translatedText = '';

                // Auxiliary function to get the name of the language based on user preference
                String getLanguageName(
                    Language language, String userPreferredLanguage) {
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

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return AlertDialog(
                      title: Text(tr('chatWindow_translateTitle')),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(
                                  child: DropdownButton<Language>(
                                    isExpanded: true,
                                    value: selectedLanguageFrom,
                                    onChanged: (Language? newValue) {
                                      setState(() {
                                        selectedLanguageFrom = newValue;
                                      });
                                    },
                                    items: languages
                                        .map<DropdownMenuItem<Language>>(
                                            (Language language) {
                                      return DropdownMenuItem<Language>(
                                        value: language,
                                        child: Text(getLanguageName(
                                            language,
                                            preferencesSnapshot.data![
                                                "currentUserLanguagePreference"])),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        20), // Space between dropdown buttons
                                Expanded(
                                  child: DropdownButton<Language>(
                                    isExpanded: true,
                                    value: selectedLanguageTo,
                                    onChanged: (Language? newValue) {
                                      setState(() {
                                        selectedLanguageTo = newValue;
                                      });
                                    },
                                    items: languages
                                        .map<DropdownMenuItem<Language>>(
                                            (Language language) {
                                      return DropdownMenuItem<Language>(
                                        value: language,
                                        child: Text(getLanguageName(
                                            language,
                                            preferencesSnapshot.data![
                                                "currentUserLanguagePreference"])),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: 20), // Space between dropdown and text
                            Text(textToTranslate), // Show original text
                            if (translatedText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(translatedText!,
                                    style:
                                        TextStyle(fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(tr('chatWindow_translateButton')),
                          onPressed: () {
                            if (selectedLanguageFrom != null &&
                                selectedLanguageTo != null) {
                              translateText(
                                      textToTranslate,
                                      getLanguageName(selectedLanguageFrom!,
                                          userPreferredLanguage),
                                      getLanguageName(selectedLanguageTo!,
                                          userPreferredLanguage))
                                  .then((result) {
                                setState(() => translatedText =
                                    result); // Update text with translation
                              });
                            }
                          },
                        ),
                        TextButton(
                          child: Text(tr('chatWindow_cancelButton')),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
