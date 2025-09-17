import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'teacher_personal_info_screen.dart'; // Import the new screen
import 'teacher_classes_screen.dart'; // Ensure this screen is imported

class TeacherProfileScreen extends StatelessWidget {
  final Teacher teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Header Section
            Container(
              padding: const EdgeInsets.all(24.0),
              color: AppColors.card,
              width: double.infinity,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.accent,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teacher.name ?? 'Teacher',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Designation: ${teacher.designation ?? 'Not Available'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Settings Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Settings Grid (My Details, Classes, Password, Privacy, Logout)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    label: 'My Details',
                    color: Colors.green.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherPersonalInfoScreen(
                            teacher: teacher,
                          ), // Pass the teacher object
                        ),
                      );
                    },
                  ),
                  // _buildSettingsTile(
                  //   icon: Icons.class_,
                  //   label: 'Classes Allotted',
                  //   color: Colors.cyan.shade100,
                  //   onTap: () {
                  //     // TODO: Navigate to the classes allotted screen
                  //   },
                  // ),
                  _buildSettingsTile(
                    icon: Icons.lock_open,
                    label: 'Change Password',
                    color: Colors.blue.shade100,
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.security,
                    label: 'Privacy',
                    color: Colors.yellow.shade100,
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: Colors.red.shade100,
                    onTap: () => _handleLogout(context),
                  ),

                  _buildSettingsTile(
                    icon: Icons.class_,
                    label: 'Classes Allotted',
                    color: Colors.green.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TeacherClassesScreen(teacher: teacher),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.textPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
