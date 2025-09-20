import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart';
import '../../../../../core/services/data_service.dart';
import '../../../../../core/models/teacher.dart';

class TeacherMarksScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherMarksScreen({super.key, required this.teacher});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();
  final TextEditingController _assessmentController = TextEditingController();

  List<dynamic> _assignedClasses = [];
  String? _selectedClassId;
  String? _selectedSubjectId;

  List<Student> _students = [];
  Map<String, int?> _marks = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAssignedClasses();
  }

  Future<void> _fetchAssignedClasses() async {
    try {
      final response = await _dataService.get(
        'teachers/assigned-classes/${widget.teacher.id}',
      );
      if (response is List) {
        setState(() {
          _assignedClasses = response;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  Future<void> _fetchStudentsForClass(String classId) async {
    setState(() {
      _isLoading = true;
      _students = [];
      _marks.clear();
    });
    try {
      final response = await _dataService.get('students/class/$classId');
      if (response is List) {
        setState(() {
          _students = response.map((item) => Student.fromJson(item)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveMarks() async {
    if (_formKey.currentState!.validate() &&
        _selectedClassId != null &&
        _selectedSubjectId != null) {
      setState(() => _isLoading = true);

      // Create a list of mark objects to send to the backend
      final marksToUpload = _students.map((student) {
        return {
          'student_id': student.id,
          'class_id': _selectedClassId,
          'subject_id': _selectedSubjectId,
          'assessment_title': _assessmentController.text,
          'marks_obtained': _marks[student.id],
          'total_marks':
              100, // Assuming a total of 100 marks for all assessments
          'uploaded_by_teacher_id': widget.teacher.id,
        };
      }).toList();

      for (var markData in marksToUpload) {
        await _dataService.post('teachers/upload-marks', markData);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _assessmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create separate lists for unique classes and subjects from assignedClasses
    final List<String> uniqueClasses = _assignedClasses
        .map((item) => '${item['class_name']} - ${item['section']}')
        .toSet()
        .toList();
    final List<String> uniqueSubjects = _assignedClasses
        .map((item) => item['subject_name'] as String)
        .toSet()
        .toList();

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
                    value: _selectedClassId,
                    items: _assignedClasses.map((item) {
                      return DropdownMenuItem(
                        value: item['class_id'] as String,
                        child: Text(
                          '${item['class_name']} - ${item['section']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClassId = newValue;
                        _selectedSubjectId = null; // Reset subject
                      });
                      if (newValue != null) {
                        _fetchStudentsForClass(newValue);
                      }
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSubjectId,
                    items: _assignedClasses
                        .where((item) => item['class_id'] == _selectedClassId)
                        .map((item) {
                          return DropdownMenuItem(
                            value: item['subject_id'] as String,
                            child: Text(item['subject_name'] as String),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubjectId = newValue;
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
            if (_selectedClassId != null && _selectedSubjectId != null)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                    ? const Center(
                        child: Text('No students found for this class.'),
                      )
                    : ListView.builder(
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
                              title: Text(student.name ?? 'Student'),
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
                                      _marks[student.id!] = int.tryParse(value);
                                    } else {
                                      _marks.remove(student.id!);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            if (_selectedClassId != null && _selectedSubjectId != null)
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
