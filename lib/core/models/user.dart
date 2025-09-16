// lib/core/models/user.dart

enum UserType { student, teacher, admin, none }

class User {
  final String id;
  final String name;
  final String email;
  final UserType type;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      type: _stringToUserType(json['type'] as String),
    );
  }
}

UserType _stringToUserType(String typeString) {
  switch (typeString.toLowerCase()) {
    case 'student':
      return UserType.student;
    case 'teacher':
      return UserType.teacher;
    case 'admin':
      return UserType.admin;
    default:
      return UserType.none;
  }
}
