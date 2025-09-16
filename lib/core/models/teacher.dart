// lib/core/models/teacher.dart
import 'user.dart';

class Teacher extends User {
  final String designation;

  Teacher({
    required super.id,
    required super.name,
    required super.email,
    required this.designation,
  }) : super(type: UserType.teacher);

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      designation: json['designation'] as String,
    );
  }
}
