class User {
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String password; // Consider removing this if not needed for display.
  final DateTime? birthday;
  final String country;
  final String? bio;
  final String? imageUrl; // Can be null if the user does not have an image
  final int friendsCount; // For now, it will be a static value
  bool isOnline;
  DateTime? lastSeen;

  User({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.password,
    this.birthday,
    required this.country,
    this.bio = '',
    this.imageUrl,
    this.friendsCount = 0, // Initialize in 0 by default
    this.isOnline = false, // Initialize in false by default
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      password: json['password'] ??
          '', // It's uncommon to fetch passwords. Be cautious.
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      country: json['country'] ?? '',
      bio: json['bio'] ?? '',
      imageUrl: json['user_img']
          as String?, // Assume this field exists in your JSON for the image
      friendsCount: json['friends_count'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      // FriendsCount and other relational data handling can be added later.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'birthday': birthday?.toIso8601String(),
      'country': country,
      'bio': bio,
      'user_img': imageUrl,
      'friendsCount': friendsCount,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}
