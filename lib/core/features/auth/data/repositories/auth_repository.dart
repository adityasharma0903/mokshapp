// lib/core/features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/user.dart';
import 'package:my_app/core/models/student.dart'; // Import Student model
import 'package:my_app/core/models/teacher.dart'; // Import Teacher model

class AuthRepository {
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);
        return User.fromJson(userData);
      } else {
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // New method to fetch the complete student profile after login
  Future<Student?> getStudentProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/students/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> studentData = jsonDecode(response.body);
        return Student.fromJson(studentData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching student profile: $e');
      return null;
    }
  }

  // You will also need a similar method for teachers
  Future<Teacher?> getTeacherProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/teachers/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> teacherData = jsonDecode(response.body);
        return Teacher.fromJson(teacherData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching teacher profile: $e');
      return null;
    }
  }
}
