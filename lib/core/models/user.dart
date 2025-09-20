// lib/core/models/user.dart

enum UserType { student, teacher, admin, driver, none }

class User {
  final String id;
  final String? name;
  final String email;
  final UserType type;

  User({required this.id, this.name, required this.email, required this.type});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      type: _stringToUserType(json['user_type'] as String),
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
    case 'driver':
      return UserType.driver;
    default:
      return UserType.none;
  }
}
