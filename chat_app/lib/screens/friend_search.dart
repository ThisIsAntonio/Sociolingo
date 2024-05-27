import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FriendSearch extends StatelessWidget {
final FirebaseFirestore firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

Map<String,bool> testUser = {
    'Noah': true,
    'isaiah' : false,
    'calvin': false,
    'david' : true,
};




 Future<List<DocumentSnapshot>>? searchResults;

Future<List<DocumentSnapshot>> searchUsers(String searchTerm) async {
  List<String> searchIds = [
    
  ];

  // Assuming you have a Firestore collection named 'items'
  var searchQuery = await firestore 
      .collection('users')
      .where('name', isGreaterThanOrEqualTo: 'El')
      .where('name', isLessThan: 'Em')      
      .limit(15)
      .get();

  searchQuery.docs.forEach((doc) { });


  return searchQuery.docs;
}


@override
Widget build(BuildContext context) {
return Scaffold(
      
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (name) {
                searchUsers(name);
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child:  
            FutureBuilder<List<DocumentSnapshot>>(
              future: searchResults,
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No results found.'));
              }

              List<DocumentSnapshot> docs = snapshot.data!;
              return ListView.builder(
                itemCount: testUser.length,
                itemBuilder: (context, index) {
                  //var data = docs[index].data() as Map<String, dynamic>;
                  var data = testUser;
                  return ListTile(
                   //title: Text(data[widget.fieldName]),
                   title: Text(testUser.keys.first),
                  );
                },
              );
            },
            ), 
          ),
        ],
      ),
    );
  }

}