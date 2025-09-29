// lib/features/student_dashboard/presentation/screens/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:my_app/core/features/student_dashboard/presentation/screens/track_vehicle_dashboard.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart'; // Import Student model
import '../../../../../core/services/data_service.dart';
import 'student_announcements_screen.dart';
import 'student_marks_screen.dart';
import 'student_attendance_view_screen.dart';
import 'student_schedule_screen.dart';
import 'student_fees_screen.dart';
import 'student_profile_screen.dart';
import 'student_leave_screen.dart';
import 'track_vehicle_screen.dart';
import 'package:badges/badges.dart' as badges;

class StudentDashboardScreen extends StatefulWidget {
  final Student student;
  const StudentDashboardScreen({super.key, required this.student});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final DataService _dataService = DataService();
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final response = await _dataService.get(
      'announcements/unread-count/${widget.student.id}',
    );
    if (mounted && response is Map && response['unread_count'] != null) {
      setState(() {
        _notificationCount = response['unread_count'];
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _dataService.put(
      'announcements/mark-as-read/${widget.student.id}',
      {},
    );
    if (mounted) {
      setState(() {
        _notificationCount = 0;
      });
    }
  }

  Widget _buildAcademicCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    int? unreadCount,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title == 'Announcements' &&
                unreadCount != null &&
                unreadCount > 0)
              badges.Badge(
                badgeContent: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                child: Icon(icon, size: 40, color: AppColors.primary),
              )
            else
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
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 16.0),
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.student.name ?? 'Student',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          badges.Badge(
                            badgeContent: Text(
                              _notificationCount.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            showBadge: _notificationCount > 0,
                            child: IconButton(
                              onPressed: () {
                                _markAllAsRead();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentAnnouncementsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentProfileScreen(
                                    student: widget.student,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0),
              child: Text(
                'Academics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
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
                    _markAllAsRead();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const StudentAnnouncementsScreen(),
                      ),
                    );
                  },
                  unreadCount: _notificationCount,
                ),
                _buildAcademicCard(
                  context,
                  title: 'Marks',
                  icon: Icons.assignment_turned_in,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentMarksScreen(student: widget.student),
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
                        builder: (context) => StudentAttendanceViewScreen(
                          student: widget.student,
                        ),
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
                        builder: (context) =>
                            StudentLeaveScreen(student: widget.student),
                      ),
                    );
                  },
                ),

                // _buildAcademicCard(
                //   context,
                //   title: 'Track Vehicle',
                //   icon: Icons.location_on,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) =>
                //             TrackVehicleScreen(student: widget.student),
                //       ),
                //     );
                //   },
                // ),
                _buildAcademicCard(
                  context,
                  title: 'Track All Vehicle',
                  icon: Icons.location_on,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TrackVehicleDashboard(student: widget.student),
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

  // The helper function is moved inside the class and correctly uses widget.student
  //   Widget _buildAcademicCard(
  //     BuildContext context, {
  //     required String title,
  //     required IconData icon,
  //     required VoidCallback onTap,
  //     int? unreadCount,
  //   }) {
  //     return InkWell(
  //       onTap: onTap,
  //       child: Card(
  //         elevation: 2,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             if (title == 'Announcements' &&
  //                 unreadCount != null &&
  //                 unreadCount > 0)
  //               badges.Badge(
  //                 badgeContent: Text(
  //                   unreadCount.toString(),
  //                   style: const TextStyle(color: Colors.white),
  //                 ),
  //                 child: Icon(icon, size: 40, color: AppColors.primary),
  //               )
  //             else
  //               Icon(icon, size: 40, color: AppColors.primary),
  //             const SizedBox(height: 8),
  //             Text(
  //               title,
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
}
