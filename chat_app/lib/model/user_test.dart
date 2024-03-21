import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserSeeder {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> firstNames = [
    "Aria",
    "Liam",
    "Sophia",
    "Mason",
    "Ella",
    "Noah",
    "Ava",
    "James",
    "Mia",
    "Olivia",
    "Jacob",
    "Amelia",
    "Ethan",
    "Isabella",
    "Alexander",
    "Charlotte",
    "Michael",
    "Harper",
    "Benjamin",
    "Madison"
  ];

  final List<String> lastNames = [
    "Miller",
    "Taylor",
    "Wilson",
    "Moore",
    "Anderson",
    "Thomas",
    "Jackson",
    "White",
    "Harris",
    "Martin",
    "Thompson",
    "Garcia",
    "Martinez",
    "Robinson",
    "Clark",
    "Rodriguez",
    "Lewis",
    "Lee",
    "Walker",
    "Hall"
  ];

  final List<String> countries = [
    "Estados Unidos",
    "México",
    "España",
    "Filipinas",
    "Argentina",
    "Colombia",
    "Canadá",
    "Perú",
    "Venezuela",
    "Chile",
    "Guatemala",
    "Ecuador",
    "Bolivia",
    "Cuba",
    "Honduras",
    "Paraguay",
    "Nicaragua",
    "El Salvador",
    "Costa Rica",
    "Puerto Rico"
  ];

  final String bio =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec varius porta neque.";

  final List<String> imageUrls = [
    "https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/profile_pictures%2Fsociolingo.project%40gmail.com%2F2024-03-06%2016%3A00%3A34.630107.png?alt=media&token=80f1915f-0f6d-45c8-961d-05476ba045a1",
    "https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/profile_pictures%2F2024-02-27%2017%3A43%3A21.597662.png?alt=media&token=5b714014-2c5b-4b89-8759-b4fb5bc93dfa",
    "https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/profile_pictures%2Fsociolingo.project%40gmail.com%2F2024-03-06%2016%3A01%3A34.925784.png?alt=media&token=9d038739-a760-400c-8f64-8c76025528bf",
    "https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/profile_pictures%2Fsociolingo.project%40gmail.com%2F2024-03-06%2016%3A01%3A34.925784.png?alt=media&token=9d038739-a760-400c-8f64-8c76025528bf"
  ];

  String generateRandomHobbyId() {
    int topicId = random.nextInt(20) + 1; // '000' a '020'
    int hobbyId = random.nextInt(5) + 1; // '001' a '005'
    return 'hobby_${topicId.toString().padLeft(3, '0')}_${hobbyId.toString().padLeft(3, '0')}';
  }

  Random random = Random();

  void seedUsers(int count) {
    for (int i = 0; i < count; i++) {
      String email = "user${i}@example.com";
      String firstName = firstNames[random.nextInt(firstNames.length)];
      String lastName = lastNames[random.nextInt(lastNames.length)];
      String country = countries[random.nextInt(countries.length)];
      DateTime birthday = DateTime.now()
          .subtract(Duration(days: random.nextInt(365 * 30) + 365 * 18));
      bool isOnline = random.nextBool();

      String imageUrl = imageUrls[random.nextInt(imageUrls.length)];

      List<String> hobbies = List.generate(3, (_) => generateRandomHobbyId());

      Map<String, dynamic> userData = {
        "bio": bio,
        "birthday": birthday.toIso8601String(),
        "country": country,
        "email": email,
        "first_name": firstName,
        "first_time": true,
        "imageUrl": imageUrl,
        "isOnline": isOnline,
        "is_active": true,
        "join_date": DateTime.now().toIso8601String(),
        "language_preference": "es",
        "last_name": lastName,
        "messaging_token": "",
        "phone_number": "+1 1111111111",
        "selectedHobbies": hobbies,
      };

      // Add the user to Firebase
      firestore.collection('users').add(userData).then((docRef) {
        print("Usuario ${docRef.id} agregado exitosamente.");
      }).catchError((error) {
        print("Error agregando usuario: $error");
      });
    }
  }
}
