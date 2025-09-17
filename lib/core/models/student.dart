// lib/core/models/student.dart

import 'package:my_app/core/models/user.dart';

class Student extends User {
  final String? rollNumber;
  final String? gender;
  final DateTime? dob;
  final String? nationality;
  final String? religion;
  final String? bloodGroup;
  final String? fatherName;
  final String? motherName;
  final String? fatherEmail;
  final String? contactNumber;
  final String? address;
  final String? className;
  final String? section;
  final String? classTeacherName;
  final String? transport;
  final bool? hasSibling;
  final String? photographUrl;
  final Map<String, bool> attendance;

  Student({
    required super.id,
    super.name, // Not required in the constructor
    required super.email,
    this.rollNumber,
    this.gender,
    this.dob,
    this.nationality,
    this.religion,
    this.bloodGroup,
    this.fatherName,
    this.motherName,
    this.fatherEmail,
    this.contactNumber,
    this.address,
    this.className,
    this.section,
    this.classTeacherName,
    this.transport,
    this.hasSibling,
    this.photographUrl,
    this.attendance = const {},
  }) : super(type: UserType.student);

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: (json['student_id'] as String?) ?? (json['id'] as String?) ?? '',
      name: json['name'] as String?,
      email: (json['email'] as String?) ?? '',
      rollNumber: json['roll_number'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] != null
          ? DateTime.tryParse(json['dob'] as String)
          : null,
      nationality: json['nationality'] as String?,
      religion: json['religion'] as String?,
      bloodGroup: json['blood_group'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      fatherEmail: json['father_email'] as String?,
      contactNumber: json['contact_number'] as String?,
      address: json['address'] as String?,
      className: json['class_name'] as String?,
      section: json['section'] as String?,
      classTeacherName: json['class_teacher_name'] as String?,
      transport: json['transport_acquired'] as String?,
      hasSibling: json['has_sibling'] != null
          ? (json['has_sibling'] as int == 1)
          : null,
      photographUrl: json['photograph_url'] as String?,
      attendance: Map<String, bool>.from(json['attendance'] ?? {}),
    );
  }
}
