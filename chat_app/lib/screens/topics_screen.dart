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
  List<String> tempSelectedHobbies =
      []; // List to keep track of temporary selected hobbies
  String? userEmail;
  String topicsTable = 'topics_en'; // Default topics table

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email;
    _getLanguageInfo();
    _loadSelectedHobbies();
  }

  void _loadSelectedHobbies() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        selectedHobbies = List<String>.from(userData['selectedHobbies'] ?? []);
        tempSelectedHobbies =
            List.from(selectedHobbies); // Initialize temporary list
      });
    }
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
        // Pop the current screen to go back to the previous one
        Navigator.pop(context, true);
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
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double padding = screenWidth > 800 ? 30.0 : 16.0;
    double maxWidth =
        screenWidth > 800 ? screenWidth * 0.6 : screenWidth * 0.95;
    double titleSize = screenWidth > 800 ? 28 : 24;
    double fontSize = screenWidth > 800 ? 18 : 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('topicScreen_title'),
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(topicsTable)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    String topicName = data['name'] ??
                        'No name'; // the name of the topic is the id

                    // now, create a new StreamBuilder for each topic to get its data
                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          document.reference.collection('hobbies').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return ListTile(
                              title: Text(
                            topicName,
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ));

                        List<Map<String, dynamic>> hobbies = snapshot.data!.docs
                            .map((doc) => {'id': doc.id, 'name': doc['name']})
                            .toList();

                        return ExpansionTile(
                          title: Text(
                            topicName,
                            style: TextStyle(
                              fontSize: fontSize,
                            ),
                          ),
                          children: hobbies.map<Widget>((hobby) {
                            // Use the ID of the hobby to work the selecction
                            bool isSelected =
                                selectedHobbies.contains(hobby['id']);
                            return ListTile(
                              title: Text(
                                hobby['name'],
                                style: TextStyle(fontSize: fontSize),
                              ),
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
                                color: isSelected
                                    ? Color.fromARGB(206, 12, 169, 153)
                                    : null,
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
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveHobbies,
        backgroundColor: Color.fromARGB(206, 12, 169, 153),
        child: Icon(Icons.save, color: Colors.white),
        tooltip: tr('topicScreen_saveHobbies'),
      ),
    );
  }
}
