import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart';

class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({super.key});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _assessmentController = TextEditingController();

  // Mock data for classes and subjects
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

  // Mock list of students. In a real app, this would be fetched based on _selectedClass.
  final List<Student> _students = [
    Student(
      id: 's001',
      name: 'Lakshya Chauhan',
      email: 'lakshya.c@example.com',
      rollNumber: '2410990523',
      attendance: {},
    ),
    Student(
      id: 's002',
      name: 'Vaibhav Katyal',
      email: 'vaibhav.k@example.com',
      rollNumber: '2410990480',
      attendance: {},
    ),
    Student(
      id: 's003',
      name: 'Ayush Sharma',
      email: 'ayush.s@example.com',
      rollNumber: '2410990524',
      attendance: {},
    ),
  ];

  // Map to hold marks for each student: studentId -> mark
  final Map<String, int?> _marks = {};
  bool _isLoading = false;

  void _saveMarks() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClass == null || _selectedSubject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a class and subject.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // TODO: Implement API call to save marks to the backend
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _assessmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Marks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Assessment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                        // TODO: Fetch students based on selected class
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSubject,
                    items: _subjects.map((String subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _assessmentController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Title',
                      hintText: 'e.g., Mid-Term Exam',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const Divider(),
            if (_selectedClass != null && _selectedSubject != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(student.name),
                        subtitle: Text('Roll No: ${student.rollNumber}'),
                        trailing: SizedBox(
                          width: 80,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Marks',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _marks[student.id] = int.tryParse(value);
                              } else {
                                _marks.remove(student.id);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_selectedClass != null && _selectedSubject != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _saveMarks,
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: const Text(
                            'Upload Marks',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
