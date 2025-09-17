// lib/features/teacher_dashboard/presentation/screens/teacher_attendance_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart';
import '../../../../../core/services/data_service.dart';
import '../../../../../core/models/teacher.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherAttendanceScreen({super.key, required this.teacher});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final DataService _dataService = DataService();

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  String? _selectedClassName;

  List<Student> _students = [];
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;

  DateTime _selectedDate = DateTime.now();
  late Map<String, bool> _attendanceStatus;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _attendanceStatus = {};
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await _dataService.get('classes');
      if (response is List) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(response);
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load classes.')));
    }
  }

  Future<void> _fetchStudentsForClass(String classId) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _attendanceStatus = {};
    });

    try {
      final response = await _dataService.get('students/class/$classId');
      if (response is List) {
        setState(() {
          _students = response.map((item) => Student.fromJson(item)).toList();
          _isLoadingStudents = false;
          for (var student in _students) {
            _attendanceStatus[student.id] = true;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load students.')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveAttendance() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a class.')));
      return;
    }

    final attendanceData = {
      'class_id': _selectedClassId,
      'record_date': _selectedDate.toIso8601String().split('T').first,
      'attendance_data': _attendanceStatus,
      'teacher_id': widget.teacher.id,
    };

    try {
      final response = await _dataService.post(
        'teachers/save-attendance',
        attendanceData,
      );
      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response['error']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save attendance.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedClassId,
                    items: _classes.map((cls) {
                      return DropdownMenuItem(
                        value: cls['class_id'] as String,
                        child: Text('${cls['class_name']} - ${cls['section']}'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClassId = newValue;
                        _selectedClassName = _classes.firstWhere(
                          (cls) => cls['class_id'] == newValue,
                        )['class_name'];
                      });
                      if (newValue != null) {
                        _fetchStudentsForClass(newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: AppColors.textPrimary,
                    ),
                    label: Text(
                      'Date: ${_selectedDate.day}/${_selectedDate.month}',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: (_selectedClassId == null)
                ? const Center(
                    child: Text('Please select a class to view students.'),
                  )
                : _isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isPresent = _attendanceStatus[student.id] ?? false;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? AppColors.success
                                : AppColors.error,
                            child: Icon(
                              isPresent ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(student.name ?? 'Student'),
                          subtitle: Text('Roll No: ${student.rollNumber}'),
                          trailing: Switch(
                            value: isPresent,
                            onChanged: (bool value) {
                              setState(() {
                                _attendanceStatus[student.id] = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedClassId == null) ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Attendance',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
