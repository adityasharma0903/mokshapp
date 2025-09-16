import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  // This is mock data. In a real app, you would fetch this from your backend.
  final List<Map<String, String>> classes = const [
    {'name': 'Operating Systems', 'code': 'CSE301', 'students': '60'},
    {'name': 'Data Structures', 'code': 'CSE202', 'students': '55'},
    {'name': 'Algorithm Analysis', 'code': 'CSE304', 'students': '45'},
    {'name': 'Database Management', 'code': 'IT401', 'students': '50'},
  ];

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
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final cls = classes[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.class_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        cls['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Code: ${cls['code']}\nStudents: ${cls['students']}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Implement navigation to a detailed class page
                        print('Tapped on ${cls['name']}');
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
