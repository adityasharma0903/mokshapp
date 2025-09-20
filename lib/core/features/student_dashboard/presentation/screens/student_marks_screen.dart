import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/data_service.dart';
import '../../../../../core/models/student.dart'; // Import Student model

class StudentMarksScreen extends StatefulWidget {
  final Student student;
  const StudentMarksScreen({super.key, required this.student});

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _studentMarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarks();
  }

  Future<void> _fetchMarks() async {
    try {
      final response = await _dataService.get(
        'students/marks/${widget.student.id}',
      );
      if (mounted && response is List) {
        setState(() {
          _studentMarks = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load marks: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _downloadReportCard() {
    // TODO: Implement the logic to download the report card
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading report card...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marks & Report Cards'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentMarks.isEmpty
          ? const Center(child: Text('No marks available.'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Marks by Subject',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMarksList(_studentMarks),
                    const SizedBox(height: 32),

                    const Text(
                      'Download Report Card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.error,
                        ),
                        title: const Text('Download Full Report Card'),
                        subtitle: const Text('For current semester'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: AppColors.primary,
                          ),
                          onPressed: _downloadReportCard,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMarksList(List<dynamic> marks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: marks.length,
      itemBuilder: (context, index) {
        final mark = marks[index];
        final marksObtained = mark['marks_obtained'] ?? 0;
        final totalMarks = mark['total_marks'] ?? 100;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              mark['subject_name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Assessment: ${mark['assessment_title'] ?? 'N/A'}'),
            trailing: Chip(
              label: Text(
                '${marksObtained}/${totalMarks}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.success,
            ),
          ),
        );
      },
    );
  }
}
