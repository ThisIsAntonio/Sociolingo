import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FriendSearch extends StatelessWidget {
final FirebaseFirestore firestore = FirebaseFirestore.instance;
//final FirebaseAuth _auth = FirebaseAuth.instance;

final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

 Future<List<DocumentSnapshot>>? searchResults;
   late Key _futureBuilderKey = UniqueKey();


Future<List<DocumentSnapshot>> searchUsers(String searchTerm) async {
  //List<String> searchIds = [ ];
  var searchQuery = await firestore 
      .collection('users')
      .where('first_name', isGreaterThanOrEqualTo: searchTerm)
      //.where('name', isLessThan: searchTerm)     
      .limit(15)
      .get();

      print(searchQuery);
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
                _futureBuilderKey = UniqueKey();
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
              key: _futureBuilderKey,
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
                itemCount: 15, //testUser.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  
                  return ListTile(
                      leading: data['imageUrl'] != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(data['imageUrl']),
                            )
                         : CircleAvatar(child: Icon(Icons.person)), 
                      title: Text(
                          '${data['first_name']} ${data['last_name']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () =>
                                //respondToFriendRequest(request.id, true),
                                Text("true")
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () =>
                                //respondToFriendRequest(request.id, false),
                                Text("false")
                          ),
                        ],
                      ),
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