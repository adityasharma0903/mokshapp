import 'dart:async';
import 'package:my_app/core/models/user.dart';

class AuthRepository {
  Future<User?> login(String email, String password) async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate successful login for a student
    if (email == 'student@college.edu' && password == 'password') {
      return User(
        id: 's123',
        name: 'Jane Doe',
        email: email,
        type: UserType.student,
      );
    }
    // Simulate successful login for a teacher
    else if (email == 'teacher@college.edu' && password == 'password') {
      return User(
        id: 't456',
        name: 'Mr. Smith',
        email: email,
        type: UserType.teacher,
      );
    }
    // Simulate successful login for an admin
    else if (email == 'admin@college.edu' && password == 'password') {
      return User(
        id: 'a789',
        name: 'Admin',
        email: email,
        type: UserType.admin,
      );
    }
    // Simulate failed login
    else {
      return null;
    }
  }
}
