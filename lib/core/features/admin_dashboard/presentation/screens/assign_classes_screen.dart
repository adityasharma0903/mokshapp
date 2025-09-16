import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AssignClassesScreen extends StatefulWidget {
  const AssignClassesScreen({super.key});

  @override
  State<AssignClassesScreen> createState() => _AssignClassesScreenState();
}

class _AssignClassesScreenState extends State<AssignClassesScreen> {
  // Mock data for teachers, classes, and subjects
  final List<String> _teachers = ['Mr. Smith', 'Ms. Jones', 'Mr. Brown'];
  String? _selectedTeacher;

  final List<String> _classes = [
    'BE-CSE-3 SEM A',
    'BE-CSE-3 SEM B',
    'BE-IT-2 SEM A',
  ];
  String? _selectedClass;

  final List<String> _subjects = [
    'Operating Systems',
    'Data Structures',
    'Algorithm Analysis',
  ];
  String? _selectedSubject;

  void _assignClass() {
    if (_selectedTeacher != null &&
        _selectedClass != null &&
        _selectedSubject != null) {
      // TODO: Implement the API call to save the class assignment to the database

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Class assigned to $_selectedTeacher successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the details.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Classes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Assign Class to a Teacher',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Teacher',
                border: OutlineInputBorder(),
              ),
              value: _selectedTeacher,
              items: _teachers.map((String teacher) {
                return DropdownMenuItem(value: teacher, child: Text(teacher));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTeacher = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(),
              ),
              value: _selectedSubject,
              items: _subjects.map((String subject) {
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubject = newValue;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _assignClass,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Assign Class',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
