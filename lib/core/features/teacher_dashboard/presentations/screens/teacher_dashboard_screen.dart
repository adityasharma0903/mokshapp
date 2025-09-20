import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../../../core/services/data_service.dart';
import 'teacher_announcements_screen.dart';
import 'teacher_marks_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_schedule_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_leaves_screen.dart';
import 'package:badges/badges.dart' as badges;

import 'Teacher_Leave_History_Screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherDashboardScreen({super.key, required this.teacher});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final DataService _dataService = DataService();
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final response = await _dataService.get(
      'announcements/unread-count/${widget.teacher.id}',
    );
    // if (mounted && response is Map && response['unread_count'] != null) {
    //   setState(() {
    //     _notificationCount = response['unread_count'];
    //   });
    // }
  }

  Future<void> _markAllAsRead() async {
    await _dataService.put(
      'announcements/mark-as-read/${widget.teacher.id}',
      {},
    );
    if (mounted) {
      setState(() {
        _notificationCount = 0;
      });
    }
  }

  // A helper function to build the dashboard cards
  Widget _buildDashboardCard(
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
                        widget.teacher.name ?? 'Teacher',
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
                                        const TeacherAnnouncementsScreen(),
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
                                  builder: (context) => TeacherProfileScreen(
                                    teacher: widget.teacher,
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
                'Teacher Tools',
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
                _buildDashboardCard(
                  context,
                  title: 'Announcements',
                  icon: Icons.campaign,
                  onTap: () {
                    _markAllAsRead();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TeacherAnnouncementsScreen(),
                      ),
                    );
                  },
                  unreadCount: _notificationCount,
                ),
                _buildDashboardCard(
                  context,
                  title: 'Upload Marks',
                  icon: Icons.assignment_turned_in,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeacherMarksScreen(teacher: widget.teacher),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Manage Attendance',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeacherAttendanceScreen(teacher: widget.teacher),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Class Schedules',
                  icon: Icons.calendar_month,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherScheduleScreen(),
                      ),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Manage Leaves',
                  icon: Icons.event_busy,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeacherLeavesScreen(teacher: widget.teacher),
                      ),
                    );
                  },
                ),

                _buildDashboardCard(
                  context,
                  title: 'Leave History',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeacherLeaveHistoryScreen(teacher: widget.teacher),
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
