// lib/core/models/student.dart

import 'package:my_app/core/models/user.dart';

class Student extends User {
  final String rollNumber;
  final Map<String, bool> attendance; // Map to store attendance by date

  Student({
    required super.id,
    required super.name,
    required super.email,
    required this.rollNumber,
    required this.attendance,
  }) : super(type: UserType.student);

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      rollNumber: json['rollNumber'] as String,
      attendance: Map<String, bool>.from(json['attendance']),
    );
  }
}
