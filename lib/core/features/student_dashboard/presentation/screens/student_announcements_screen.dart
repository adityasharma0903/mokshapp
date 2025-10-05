import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/data_service.dart';
// Import the new detail screen (assuming you save it in a separate file)
import 'announcement_detail_screen.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final DataService _dataService = DataService();
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await _dataService.get('announcements');
      if (mounted && response is List) {
        // Optional: Sort by date if available, to show latest first.
        response.sort(
          (a, b) => (b['date_posted'] ?? '').compareTo(a['date_posted'] ?? ''),
        );
        setState(() {
          _announcements = response;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load announcements.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
          ? const Center(child: Text('No announcements available.'))
          : ListView.builder(
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.campaign,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      announcement['title'] ?? 'No Title',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Show a short preview of the message
                    subtitle: Text(
                      announcement['message'] != null &&
                              announcement['message'].length > 100
                          ? announcement['message'].substring(0, 100) + '...'
                          : announcement['message'] ?? 'No message provided.',
                    ),

                    // --- MODIFICATION 1: Update Trailing ---
                    // Replace the IconButton with a simple file icon for indication
                    trailing: announcement['attachment_url'] != null
                        ? const Icon(Icons.attach_file, color: Colors.grey)
                        : null,

                    // --- MODIFICATION 2: Add onTap Navigation ---
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailScreen(
                            announcement: announcement,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
