import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:chat_app/screens/usersWithHobbies_page.dart';

class HobbiesPage extends StatefulWidget {
  final String topicId;
  final String collectionPrefix; // 'es', 'en', 'fr', etc.

  const HobbiesPage(
      {Key? key, required this.topicId, required this.collectionPrefix})
      : super(key: key);

  @override
  _HobbiesPageState createState() => _HobbiesPageState();
}

class _HobbiesPageState extends State<HobbiesPage> {
  String hobbyName = '';
  // Generate a pastel color
  Color generateRandomPastelColor() {
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
    double fontSize = screenWidth > 600 ? 18 : 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('hobbiesPage_title'),
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(
                'topics_${widget.collectionPrefix}') // This will use the correct collection prefix
            .doc(widget.topicId)
            .collection('hobbies')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> hobbies = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 2,
            ),
            itemCount: hobbies.length,
            itemBuilder: (context, index) {
              String localHobbyName = hobbies[index]['name'];
              String hobbyId = hobbies[index].id;

              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UsersWithHobbyPage(
                              hobbyId: hobbyId, hobbyName: localHobbyName)),
                    );
                  },
                  child: Card(
                    color: generateRandomPastelColor(),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          localHobbyName,
                          style: TextStyle(
                            color: Colors
                                .black, // Black text to contrast with pastel colors
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
