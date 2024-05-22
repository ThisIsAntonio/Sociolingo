import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:chat_app/screens/hobbies_page.dart';

// Topics Page
class TopicsPage extends StatefulWidget {
  @override
  _TopicsPageState createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  String collectionName = 'topics_en'; // Default Collection name
  String prefix = "en";

  @override
  void initState() {
    super.initState();
    _fetchUserLanguagePreference();
  }

  // Function to fetch the user's language preference from Firebase Authentication
  Future<void> _fetchUserLanguagePreference() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String languagePreference = doc.data()?['language_preference'] ?? 'en';
      // Create the collection name based on the language preference
      setState(() {
        collectionName = 'topics_$languagePreference';
        prefix = languagePreference;
      });
    }
  }

  // Function to generate random colors
  Color generateRandomColor() {
    return Color.fromRGBO(
      128 + Random().nextInt(128), // R
      128 + Random().nextInt(128), // G
      128 + Random().nextInt(128), // B
      1, // Opacity
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate sizes based on screen width
    double titleSize = screenWidth > 800 ? 28 : 24;
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
    double fontSize = screenWidth > 800 ? 18 : 16;

    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: Text(
          tr('topicsPage_title'),
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> topics = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // Columns number
              crossAxisSpacing: 10, // Horizont space
              mainAxisSpacing: 10, // Vertical space
              childAspectRatio: 3 / 2, // Proportion of the card
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              String topicId = topics[index].id;
              String topicName = topics[index]['name'];

              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HobbiesPage(
                          topicId: topicId,
                          collectionPrefix: prefix,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: generateRandomColor(), // Random color for each card
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          topicName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ));
            },
          );
        },
      ),
    );
  }
}
