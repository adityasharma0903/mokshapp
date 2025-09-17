import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart';
import '../../../../../core/services/data_service.dart';

class StudentAttendanceViewScreen extends StatefulWidget {
  final Student student;
  const StudentAttendanceViewScreen({super.key, required this.student});

  @override
  State<StudentAttendanceViewScreen> createState() =>
      _StudentAttendanceViewScreenState();
}

class _StudentAttendanceViewScreenState
    extends State<StudentAttendanceViewScreen> {
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      // The endpoint uses the student's ID, which is a member of the widget class
      final response = await _dataService.get(
        'students/attendance/${widget.student.id}',
      );
      if (response is List) {
        setState(() {
          _attendanceRecords = List<Map<String, dynamic>>.from(response);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load attendance data.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceRecords.isEmpty
          ? const Center(child: Text('No attendance data available.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = _attendanceRecords[index];
                  // Use a safe cast for is_present
                  final isPresent = (record['is_present'] as int) == 1;
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        isPresent ? Icons.check_circle : Icons.cancel,
                        color: isPresent ? AppColors.success : AppColors.error,
                      ),
                      title: Text('Date: ${record['record_date']}'),
                      subtitle: Text(
                        'Status: ${isPresent ? 'Present' : 'Absent'}',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
