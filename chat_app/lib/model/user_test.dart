import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class UserSeeder {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> firstNames = [
    "Giulia",
    "Oliver",
    "Amélie",
    "Youssef",
    "Carlos",
    "Isabella",
    "Ethan",
    "Fatima",
    "Lucía",
    "Chloé"
  ];

  final List<String> lastNames = [
    "Rossi",
    "Smith",
    "Dupont",
    "Al-Farsi",
    "García",
    "Bianchi",
    "Johnson",
    "Moussa",
    "Martínez",
    "Martin"
  ];

  final List<String> countries = [
    "Italia",
    "Francia",
    "Japón",
    "India",
    "Egipto",
    "Sudáfrica",
    "Australia",
    "Brasil",
    "Canadá",
    "Alemania"
  ];

  final String bio =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec varius porta neque.";

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
      String imageUrl =
          "https://firebasestorage.googleapis.com/v0/b/sociolingo-project.appspot.com/o/profile_pictures%2Fsociolingo.project%40gmail.com%2F2024-03-06%2012%3A11%3A56.319803.png?alt=media&token=4f6d4d4d-d764-440b-9772-c553ab63c982"; // Use a default or random image URL

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
        "phone_number": "+1 1111111111"
      };

      // AAdd the user to Firebase
      firestore.collection('users').add(userData).then((docRef) {
        print("Usuario ${docRef.id} agregado exitosamente.");
      }).catchError((error) {
        print("Error agregando usuario: $error");
      });
    }
  }
}
