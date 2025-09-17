import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';
import '../../../../features/student_dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../../../features/teacher_dashboard/presentations/screens/teacher_dashboard_screen.dart';
import '../../../../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/models/student.dart';
import '../../../../../core/models/teacher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // lib/core/features/auth/presentation/screens/login_screen.dart

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final user = await authRepo.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      if (user.type == UserType.student) {
        // Here, the student object needs to be fetched
        final Student? student = await authRepo.getStudentProfile(user.id);
        if (student != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentDashboardScreen(student: student),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load student profile.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else if (user.type == UserType.teacher) {
        // Corrected line: Fetch the teacher profile and pass it to the dashboard
        final Teacher? teacher = await authRepo.getTeacherProfile(user.id);
        if (teacher != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TeacherDashboardScreen(teacher: teacher),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load teacher profile.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else if (user.type == UserType.admin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'College Portal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
