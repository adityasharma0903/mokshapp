import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../../../core/services/data_service.dart';

class TeacherLeavesScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherLeavesScreen({super.key, required this.teacher});

  @override
  State<TeacherLeavesScreen> createState() => _TeacherLeavesScreenState();
}

class _TeacherLeavesScreenState extends State<TeacherLeavesScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      final response = await _dataService.get(
        'teachers/leaves/${widget.teacher.id}',
      );
      if (mounted && response is List) {
        setState(() {
          _leaveRequests = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load leave requests.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLeaveStatus(String leaveId, String status) async {
    final response = await _dataService.put('teachers/leaves/update/$leaveId', {
      'status': status,
    });
    if (mounted) {
      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request ${status.toLowerCase()}d.')),
        );
        _fetchLeaveRequests(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Leaves'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveRequests.isEmpty
          ? const Center(child: Text('No new leave requests.'))
          : ListView.builder(
              itemCount: _leaveRequests.length,
              itemBuilder: (context, index) {
                final request = _leaveRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.event_busy,
                      color: AppColors.primary,
                    ),
                    title: Text(request['student_name'] ?? 'Unknown Student'),
                    subtitle: Text(
                      'Reason: ${request['reason']}\nDates: ${request['start_date'].toString().split('T').first} to ${request['end_date'].toString().split('T').first}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                          onPressed: () => _updateLeaveStatus(
                            request['leave_id'],
                            'Approved',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: AppColors.error,
                          ),
                          onPressed: () => _updateLeaveStatus(
                            request['leave_id'],
                            'Rejected',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
