import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart'; // Import Student model

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  // Mock data for classes and students
  final List<String> _classes = [
    'BE-CSE-3 SEM A',
    'BE-CSE-3 SEM B',
    'BE-IT-2 SEM A',
  ];
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();

  // Mock list of students. In a real app, this would be fetched based on _selectedClass.
  final List<Student> _students = [
    Student(
      id: 's001',
      name: 'Lakshya Chauhan',
      email: 'lakshya.c@example.com', // Added email
      rollNumber: '2410990523',
      attendance: {},
    ),
    Student(
      id: 's002',
      name: 'Vaibhav Katyal',
      email: 'vaibhav.k@example.com', // Added email
      rollNumber: '2410990480',
      attendance: {},
    ),
    Student(
      id: 's003',
      name: 'Ayush Sharma',
      email: 'ayush.s@example.com', // Added email
      rollNumber: '2410990524',
      attendance: {},
    ),
    // ... add more students
  ];
  // Map to hold attendance status: studentId -> isPresent (true/false)
  late Map<String, bool> _attendanceStatus;

  @override
  void initState() {
    super.initState();
    _attendanceStatus = {};
    _initializeAttendanceStatus();
  }

  void _initializeAttendanceStatus() {
    for (var student in _students) {
      _attendanceStatus[student.id] = true; // Default to present
    }
  }

  // Function to show a date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to save the attendance data
  void _saveAttendance() {
    // TODO: Implement logic to save _attendanceStatus for _selectedDate and _selectedClass
    // This would likely involve an API call.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
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
          // Section for class and date selection
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
                    value: _selectedClass,
                    items: _classes.map((String cls) {
                      return DropdownMenuItem(value: cls, child: Text(cls));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClass = newValue;
                        // TODO: Fetch students for the selected class here
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Date Picker Button
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
          // Student List with Checkboxes
          Expanded(
            child: (_selectedClass == null)
                ? const Center(
                    child: Text('Please select a class to view students.'),
                  )
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
                          title: Text(student.name),
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
          // Save Attendance Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedClass == null) ? null : _saveAttendance,
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
