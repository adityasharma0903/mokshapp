import 'package:flutter/material.dart';
// url_launcher package use karna zaroori hai file open/download karne ke liye
import 'package:url_launcher/url_launcher.dart';
// To format the date/time
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';

// NOTE: You need to add the 'intl' package to your pubspec.yaml for formatting:
// dependencies:
//   intl: ^0.18.1  // Use the latest version

class AnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  // Function to handle opening the URL (improved for better download handling)
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    // Use LaunchMode.externalApplication to delegate the URL opening
    // to the external app (like browser/file manager), which often handles downloading better.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open this file or download link is invalid.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] ?? 'Detail Not Available';
    final message = announcement['message'] ?? 'No message found';
    final attachmentUrl = announcement['attachment_url'];

    // --- FIX 1: Use 'created_at' (from your backend) and format the time ---
    String formattedDateTime = 'N/A';
    final dateTimeString = announcement['created_at'];

    try {
      if (dateTimeString != null) {
        // Parse the DATETIME string from the database and convert to local time
        final postedDateTime = DateTime.parse(dateTimeString).toLocal();
        // Format the date and time (e.g., Oct 5, 2025 at 12:17 PM)
        formattedDateTime = DateFormat(
          'MMM d, yyyy HH:mm',
        ).format(postedDateTime);
      }
    } catch (e) {
      // Handle potential parsing error
      print('Date parsing error: $e');
    }
    // --- END FIX 1 ---

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
            // Date and Time
            Text(
              'Posted on: $formattedDateTime',
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
                'Tap on the link; it will open in your browser or download manager.',
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
