import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/constants/app_colors.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
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

  // Mock data for existing schedules/notes
  // In a real app, this would be fetched from a backend
  final List<Map<String, String>> _schedules = [
    {'title': 'Operating Systems Lecture 1', 'date': '2025-09-10'},
    {'title': 'Operating Systems Lab Manual', 'date': '2025-09-12'},
    {'title': 'Data Structures Syllabus', 'date': '2025-09-08'},
  ];

  Future<void> _showAddScheduleDialog() async {
    final TextEditingController titleController = TextEditingController();
    PlatformFile? selectedFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Schedule/Note'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pdf',
                              'doc',
                              'docx',
                              'png',
                              'jpg',
                            ],
                          );
                      if (result != null) {
                        setState(() {
                          selectedFile = result.files.first;
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select File'),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Selected: ${selectedFile!.name}'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement save and upload logic
                    if (titleController.text.isNotEmpty &&
                        selectedFile != null) {
                      _schedules.add({
                        'title': titleController.text,
                        'date': 'Just Now', // Placeholder
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Schedule/Note uploaded successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Schedules / Notes'),
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
                    value: _selectedClass,
                    items: _classes.map((String cls) {
                      return DropdownMenuItem(value: cls, child: Text(cls));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClass = newValue;
                        // TODO: Fetch schedules for the selected class/subject
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                        // TODO: Fetch schedules for the selected class/subject
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_selectedClass != null && _selectedSubject != null)
            Expanded(
              child: ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(schedule['title']!),
                      subtitle: Text('Uploaded: ${schedule['date']!}'),
                      trailing: const Icon(Icons.download),
                      onTap: () {
                        // TODO: Implement file download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Downloading ${schedule['title']}...',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          if (_selectedClass == null || _selectedSubject == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Please select a class and subject to view and upload schedules.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (_selectedClass != null && _selectedSubject != null)
          ? FloatingActionButton.extended(
              onPressed: _showAddScheduleDialog,
              label: const Text('Add New'),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
