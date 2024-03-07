import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

// Topics Page
class TopicsPage extends StatefulWidget {
  @override
  _TopicsPageState createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  String collectionName = 'topics_en'; // Default Collection name

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
      });
    }
  }

  // Function to generate random colors
  Color generateRandomColor() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: Text(tr('topicsPage_title')),
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
              crossAxisCount: 2, // Columns number
              crossAxisSpacing: 10, // Horizont space
              mainAxisSpacing: 10, // Vertical space
              childAspectRatio: 3 / 2, // Proportion of the card
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              String topicName = topics[index]['name'];

              return Card(
                color: generateRandomColor(), // Random color for each card
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      topicName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
