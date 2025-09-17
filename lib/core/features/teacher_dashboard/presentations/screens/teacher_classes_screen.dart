import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../../../core/services/data_service.dart';

class TeacherClassesScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherClassesScreen({super.key, required this.teacher});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _assignedClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedClasses();
  }

  Future<void> _fetchAssignedClasses() async {
    try {
      final response = await _dataService.get(
        'teachers/classes/${widget.teacher.id}',
      );
      if (response is List) {
        setState(() {
          _assignedClasses = response;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load classes.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes Allotted'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Allotted Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _assignedClasses.isEmpty
                  ? const Center(child: Text('No classes assigned yet.'))
                  : ListView.builder(
                      itemCount: _assignedClasses.length,
                      itemBuilder: (context, index) {
                        final cls = _assignedClasses[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.class_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              '${cls['class_name']} - ${cls['section']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Subjects: ${cls['subjects'].join(', ')}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              // TODO: Implement navigation to a detailed class page
                              print('Tapped on ${cls['class_name']}');
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
