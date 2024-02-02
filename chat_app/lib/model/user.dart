class User {
  final String email;
  final String username;
  final String bio;

  User({required this.email, required this.username, required this.bio});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      username: json['username'],
      bio: json['bio'] ?? '',
    );
  }
}
