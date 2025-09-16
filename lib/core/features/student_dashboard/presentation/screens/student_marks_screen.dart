import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class StudentMarksScreen extends StatefulWidget {
  const StudentMarksScreen({super.key});

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen> {
  // Mock data for student marks
  final List<Map<String, dynamic>> _studentMarks = [
    {'subject': 'Operating Systems', 'marks': 85, 'total': 100},
    {'subject': 'Data Structures', 'marks': 92, 'total': 100},
    {'subject': 'Algorithm Analysis', 'marks': 78, 'total': 100},
    {'subject': 'Database Management', 'marks': 88, 'total': 100},
  ];

  void _downloadReportCard() {
    // TODO: Implement the logic to download the report card
    // This would typically involve an API call to get the PDF URL and then a download service.
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Marks by Subject Section
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

              // Report Card Download Section
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
                    icon: const Icon(Icons.download, color: AppColors.primary),
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

  Widget _buildMarksList(List<Map<String, dynamic>> marks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: marks.length,
      itemBuilder: (context, index) {
        final mark = marks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              mark['subject'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Total: ${mark['total']}'),
            trailing: Chip(
              label: Text(
                '${mark['marks']}',
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
