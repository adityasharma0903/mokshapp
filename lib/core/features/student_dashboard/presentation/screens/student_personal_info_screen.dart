import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class StudentPersonalInfoScreen extends StatelessWidget {
  const StudentPersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image and Name Section
              Card(
                elevation: 0,
                color: AppColors.background,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accent,
                      backgroundImage: const NetworkImage(
                        'https://via.placeholder.com/150',
                      ), // Replace with actual image
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Student Name', // Replace with dynamic name
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Student's Details Section
              _buildSectionTitle('Student\'s Details'),
              const SizedBox(height: 8),
              _buildInfoRow('Name', 'Student Name'),
              _buildInfoRow('Roll No.', '25'),
              _buildInfoRow('Gender', 'Male'),
              _buildInfoRow('D.O.B.', '12-10-2006'),
              _buildInfoRow('Category', 'General'),
              _buildInfoRow('Mobile No.', '7896541230'),
              _buildInfoRow('Email', 'student@college.edu'),
              _buildInfoRow('Date of Admission', '29-05-2024'),

              const SizedBox(height: 24),

              // Student's Custom Field(s) Section
              _buildSectionTitle('Student\'s Custom Field(s)'),
              const SizedBox(height: 8),
              _buildInfoRow('Blood Group', 'B+'),
              _buildInfoRow('Batch Duration For ID', '2024-2025'),
              _buildInfoRow('College Name for ID', 'Blueberry Fields School'),
              _buildInfoRow('Class', '5th B '),
              _buildInfoRow('Year', '2025'),
            ],
          ),
        ),
      ),
    );
  }

  // A helper widget to create the section titles
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(color: AppColors.textSecondary),
      ],
    );
  }

  // A helper widget to create each info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
