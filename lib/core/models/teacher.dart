// lib/core/models/teacher.dart
import 'package:my_app/core/models/user.dart';

class Teacher extends User {
  final String? designation;
  final String? gender;
  final DateTime? dob;
  final String? maritalStatus;
  final String? nationality;
  final String? bloodGroup;
  final String? contactNumber;
  final String? permanentAddress;
  final String? currentAddress;
  final String? spouseName;
  final String? photographUrl;
  final String? academicDocsUrl;
  final String? professionalDocsUrl;
  final String? fatherName; // <-- Add this field
  final String? motherName; // <-- Add this field

  Teacher({
    required super.id,
    super.name,
    required super.email,
    this.designation,
    this.gender,
    this.dob,
    this.maritalStatus,
    this.nationality,
    this.bloodGroup,
    this.contactNumber,
    this.permanentAddress,
    this.currentAddress,
    this.spouseName,
    this.fatherName, // <-- Add this to the constructor
    this.motherName,
    this.photographUrl,
    this.academicDocsUrl,
    this.professionalDocsUrl,
  }) : super(type: UserType.teacher);

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['teacher_id'] as String,
      name: json['name'] as String? ?? 'No Name Provided',
      email: json['email'] as String,
      designation: json['designation'] as String? ?? 'Not Available',
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      maritalStatus: json['marital_status'] as String?,
      nationality: json['nationality'] as String?,
      bloodGroup: json['blood_group'] as String?,
      contactNumber: json['contact_number'] as String?,
      permanentAddress: json['permanent_address'] as String?,
      currentAddress: json['current_address'] as String?,
      fatherName: json['father_name'] as String?, // <-- Map from JSON
      motherName: json['mother_name'] as String?, // <-- Map from JSON
      spouseName: json['spouse_name'] as String?,
      photographUrl: json['photograph_url'] as String?,
      academicDocsUrl: json['academic_docs_url'] as String?,
      professionalDocsUrl: json['professional_docs_url'] as String?,
    );
  }
}
