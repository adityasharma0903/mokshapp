import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';

class TeacherPersonalInfoScreen extends StatelessWidget {
  final Teacher teacher;

  const TeacherPersonalInfoScreen({super.key, required this.teacher});

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
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.accent,
                      backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150', // Use teacher.photographUrl if available
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      teacher.name ?? 'Teacher Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Teacher's Personal Details
              _buildSectionTitle('Personal Details'),
              const SizedBox(height: 8),
              _buildInfoRow('Full Name', teacher.name ?? 'Not available'),
              _buildInfoRow('Email', teacher.email ?? 'Not available'),
              _buildInfoRow(
                'Designation',
                teacher.designation ?? 'Not available',
              ),
              _buildInfoRow('Gender', teacher.gender ?? 'Not available'),
              _buildInfoRow(
                'Date of Birth',
                teacher.dob?.toIso8601String().split('T').first ??
                    'Not available',
              ),
              _buildInfoRow(
                'Nationality',
                teacher.nationality ?? 'Not available',
              ),
              _buildInfoRow(
                'Blood Group',
                teacher.bloodGroup ?? 'Not available',
              ),
              _buildInfoRow(
                'Marital Status',
                teacher.maritalStatus ?? 'Not available',
              ),

              const SizedBox(height: 24),

              // Contact & Address Details
              _buildSectionTitle('Contact & Address'),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Contact Number',
                teacher.contactNumber ?? 'Not available',
              ),
              _buildInfoRow(
                'Permanent Address',
                teacher.permanentAddress ?? 'Not available',
              ),
              _buildInfoRow(
                'Current Address',
                teacher.currentAddress ?? 'Not available',
              ),

              const SizedBox(height: 24),

              // Family Details
              _buildSectionTitle('Family Details'),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Father\'s Name',
                teacher.fatherName ?? 'Not available',
              ),
              _buildInfoRow(
                'Mother\'s Name',
                teacher.motherName ?? 'Not available',
              ),
              _buildInfoRow(
                'Spouse\'s Name',
                teacher.spouseName ?? 'Not available',
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
