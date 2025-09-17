import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/data_service.dart';

class AssignClassesScreen extends StatefulWidget {
  const AssignClassesScreen({super.key});

  @override
  State<AssignClassesScreen> createState() => _AssignClassesScreenState();
}

class _AssignClassesScreenState extends State<AssignClassesScreen> {
  final _dataService = DataService();

  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;

  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Fetch teachers, classes, and subjects from the backend
    final teachersResponse = await _dataService.get('teachers');
    final classesResponse = await _dataService.get('classes');
    final subjectsResponse = await _dataService.get('subjects');

    if (teachersResponse is List &&
        classesResponse is List &&
        subjectsResponse is List) {
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(teachersResponse);
        _classes = List<Map<String, dynamic>>.from(classesResponse);
        _subjects = List<Map<String, dynamic>>.from(subjectsResponse);
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load data.')));
    }
  }

  void _assignClass() async {
    if (_selectedTeacherId != null &&
        _selectedClassId != null &&
        _selectedSubjectId != null) {
      final assignmentData = {
        'teacher_id': _selectedTeacherId,
        'class_id': _selectedClassId,
        'subject_id': _selectedSubjectId,
      };

      final response = await _dataService.post(
        'teachers/assign-class',
        assignmentData,
      );

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class assigned successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
              value: _selectedTeacherId,
              items: _teachers.map((t) {
                return DropdownMenuItem(
                  value: t['teacher_id'] as String,
                  child: Text(t['name'] as String),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTeacherId = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(),
              ),
              value: _selectedSubjectId,
              items: _subjects.map((sub) {
                return DropdownMenuItem(
                  value: sub['subject_id'] as String,
                  child: Text(sub['subject_name'] as String),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubjectId = newValue;
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
