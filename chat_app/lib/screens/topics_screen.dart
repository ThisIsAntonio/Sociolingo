import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class TopicsScreen extends StatefulWidget {
  final String userId;
  final int screenID;

  const TopicsScreen({Key? key, required this.userId, required this.screenID})
      : super(key: key);

  @override
  _TopicsScreenState createState() => _TopicsScreenState();
}

// Class for the state of the TopicsScreen
class _TopicsScreenState extends State<TopicsScreen> {
  List<String> selectedHobbies = []; // List to keep track of selected hobbies
  String? userEmail;
  String topicsTable = 'topics_en'; // Default topics table

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email;
    _getLanguageInfo();
  }

  // Function to save the selected hobbies
  void _saveHobbies() async {
    var user = FirebaseAuth.instance.currentUser;
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(user?.uid);
    if (widget.screenID == 1) {
      // Case when the user wants to save the hobbies information
      await userDoc.set({
        'selectedHobbies': selectedHobbies,
      }, SetOptions(merge: true)).then((_) {
        _onSaveSuccess();
      }).catchError((error) {
        _onSaveError(error);
      });
    } else if (widget.screenID == 2) {
      // Case when the user wants to update the hobbies information
      await userDoc
          .update({'selectedHobbies': selectedHobbies}).then((_) async {
        _onSaveSuccess();
      }).catchError((error) {
        _onSaveError(error);
      });
    }
  }

  // Function to get the language preference
  void _getLanguageInfo() async {
    // Get the current user ID
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Get the user language preference
      String languagePreference =
          userData['language_preference'] ?? 'en'; // English by default

      setState(() {
        topicsTable = 'topics_$languagePreference';
      });
    }
  }

  // Functions to handle the success and error cases when saving the hobbies
  void _onSaveSuccess() {
    if (userEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('topicScreen_hobbiesUpdateSuccessful'))),
      );
      if (widget.screenID == 2) {
        // Redirect to the User Profile after saving the data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    userEmail: userEmail!,
                    returnScreen: 3,
                  )),
        );
      } else {
        // Redirect to the MainScreen after saving the data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    userEmail: userEmail!,
                  )),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('topicScreen_hobbiesUpdateFailed'))),
      );
    }
  }

  // Function to handle the error case when saving the hobbies
  void _onSaveError(error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('topicScreen_hobbiesErrorSaving') + '$error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('topicScreen_title')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(topicsTable).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String topicName =
                  data['name'] ?? 'No name'; // the name of the topic is the id

              // now, create a new StreamBuilder for each topic to get its data
              return StreamBuilder<QuerySnapshot>(
                stream: document.reference.collection('hobbies').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return ListTile(title: Text(topicName));

                  List<Map<String, dynamic>> hobbies = snapshot.data!.docs
                      .map((doc) => {'id': doc.id, 'name': doc['name']})
                      .toList();

                  return ExpansionTile(
                    title: Text(topicName),
                    children: hobbies.map<Widget>((hobby) {
                      // Usa el ID del hobby para manejar la selección
                      bool isSelected = selectedHobbies.contains(hobby['id']);
                      return ListTile(
                        title: Text(hobby['name']),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedHobbies.remove(hobby['id']);
                            } else {
                              selectedHobbies.add(hobby['id']);
                            }
                          });
                        },
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: isSelected ? Colors.green : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveHobbies,
        child: Icon(Icons.save),
        tooltip: tr('topicScreen_saveHobbies'),
      ),
    );
  }
}
