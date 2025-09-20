import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../../../core/services/data_service.dart';

class TeacherLeaveHistoryScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherLeaveHistoryScreen({super.key, required this.teacher});

  @override
  State<TeacherLeaveHistoryScreen> createState() =>
      _TeacherLeaveHistoryScreenState();
}

class _TeacherLeaveHistoryScreenState extends State<TeacherLeaveHistoryScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _leaveHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaveHistory();
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final response = await _dataService.get(
        'teachers/leave-history/${widget.teacher.id}',
      );
      if (mounted && response is List) {
        setState(() {
          _leaveHistory = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leave history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveHistory.isEmpty
          ? const Center(child: Text('No leave history found.'))
          : ListView.builder(
              itemCount: _leaveHistory.length,
              itemBuilder: (context, index) {
                final leave = _leaveHistory[index];
                Color statusColor;
                if (leave['status'] == 'Approved') {
                  statusColor = AppColors.success;
                } else if (leave['status'] == 'Rejected') {
                  statusColor = AppColors.error;
                } else {
                  statusColor = AppColors.textSecondary;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      'Student: ${leave['student_name']} (${leave['roll_number']})',
                    ),
                    subtitle: Text('Reason: ${leave['reason']}'),
                    trailing: Chip(
                      label: Text(leave['status']),
                      backgroundColor: statusColor,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
