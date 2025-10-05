import 'package:flutter/material.dart';
// url_launcher package use karna zaroori hai file open/download karne ke liye
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  // Function to handle opening the URL
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cant open this file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] ?? 'Not available detail ';
    final message = announcement['message'] ?? 'No message found';
    final attachmentUrl = announcement['attachment_url'];

    // Date ko format karna
    final date = announcement['date_posted'] != null
        ? DateTime.parse(
            announcement['date_posted'],
          ).toLocal().toString().split(' ')[0]
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Date
            Text(
              'Post has been done : $date',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 30),

            // Full Message
            Text(message, style: Theme.of(context).textTheme.bodyLarge),

            // Attachment Section
            if (attachmentUrl != null) ...[
              const Divider(height: 30),
              Text(
                'Attachments:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attachment, color: AppColors.primary),
                title: const Text(
                  'File Download',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
                trailing: const Icon(Icons.file_download),
                // Tap hone par URL open hoga
                onTap: () => _launchUrl(context, attachmentUrl),
              ),
              const Text(
                'tap on the link it will open in your browser or download manager.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
