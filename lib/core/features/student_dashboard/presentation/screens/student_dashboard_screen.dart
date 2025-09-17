// lib/features/student_dashboard/presentation/screens/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart'; // Import Student model
import 'student_announcements_screen.dart';
import 'student_marks_screen.dart';
import 'student_attendance_view_screen.dart';
import 'student_schedule_screen.dart';
import 'student_fees_screen.dart';
import 'student_profile_screen.dart';
import 'student_leave_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  final Student student;

  const StudentDashboardScreen({super.key, required this.student});

  // A helper function to build the academic cards
  Widget _buildAcademicCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Name, Search, and Icons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        student.name ?? 'Student', // Display student name here
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              // TODO: Navigate to notification screen
                            },
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudentProfileScreen(student: student),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      hintText: 'Search',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            // Academics Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Academics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildAcademicCard(
                  context,
                  title: 'Announcements',
                  icon: Icons.campaign,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const StudentAnnouncementsScreen(),
                      ),
                    );
                  },
                ),
                _buildAcademicCard(
                  context,
                  title: 'Marks',
                  icon: Icons.assignment_turned_in,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentMarksScreen(),
                      ),
                    );
                  },
                ),
                _buildAcademicCard(
                  context,
                  title: 'Attendance',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentAttendanceViewScreen(student: student),
                      ),
                    );
                  },
                ),
                _buildAcademicCard(
                  context,
                  title: 'Time Table',
                  icon: Icons.calendar_month,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentScheduleScreen(),
                      ),
                    );
                  },
                ),
                _buildAcademicCard(
                  context,
                  title: 'Fees',
                  icon: Icons.payments,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentFeesScreen(),
                      ),
                    );
                  },
                ),
                _buildAcademicCard(
                  context,
                  title: 'Apply Leave',
                  icon: Icons.date_range,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentLeaveScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
