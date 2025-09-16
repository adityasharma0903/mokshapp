import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class TeacherLeavesScreen extends StatelessWidget {
  const TeacherLeavesScreen({super.key});

  // Mock list of leave requests
  final List<Map<String, dynamic>> _leaveRequests = const [
    {
      'name': 'Vaibhav Katyal',
      'reason': 'Family emergency',
      'startDate': '2025-09-20',
      'endDate': '2025-09-22',
      'status': 'Pending',
    },
    {
      'name': 'Ayush Sharma',
      'reason': 'Medical appointment',
      'startDate': '2025-09-18',
      'endDate': '2025-09-18',
      'status': 'Pending',
    },
  ];

  void _approveLeave(BuildContext context) {
    // TODO: Implement API call to approve the leave request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave Approved!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _rejectLeave(BuildContext context) {
    // TODO: Implement API call to reject the leave request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave Rejected!'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Leaves'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _leaveRequests.length,
        itemBuilder: (context, index) {
          final request = _leaveRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(request['name']),
              subtitle: Text(
                '${request['reason']}\nDates: ${request['startDate']} to ${request['endDate']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    onPressed: () => _approveLeave(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.error),
                    onPressed: () => _rejectLeave(context),
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
