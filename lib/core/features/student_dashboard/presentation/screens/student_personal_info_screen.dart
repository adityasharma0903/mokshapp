import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart';

class StudentPersonalInfoScreen extends StatelessWidget {
  final Student student;

  const StudentPersonalInfoScreen({super.key, required this.student});

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
                        'https://via.placeholder.com/150', // Use student.photographUrl if available
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student.name ?? 'Student Name',
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

              // Student's Personal Details
              _buildSectionTitle('Personal Details'),
              const SizedBox(height: 8),
              _buildInfoRow('Full Name', student.name ?? 'Not available'),
              _buildInfoRow('Roll No.', student.rollNumber ?? 'Not available'),
              _buildInfoRow('Gender', student.gender ?? 'Not available'),
              _buildInfoRow(
                'Date of Birth',
                student.dob?.toIso8601String().split('T').first ??
                    'Not available',
              ),
              _buildInfoRow(
                'Nationality',
                student.nationality ?? 'Not available',
              ),
              _buildInfoRow('Religion', student.religion ?? 'Not available'),
              _buildInfoRow(
                'Blood Group',
                student.bloodGroup ?? 'Not available',
              ),

              const SizedBox(height: 24),

              // Family Details Section
              _buildSectionTitle('Family Details'),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Father\'s Name',
                student.fatherName ?? 'Not available',
              ),
              _buildInfoRow(
                'Mother\'s Name',
                student.motherName ?? 'Not available',
              ),
              _buildInfoRow(
                'Father\'s Email',
                student.fatherEmail ?? 'Not available',
              ),
              _buildInfoRow(
                'Contact Number',
                student.contactNumber ?? 'Not available',
              ),

              const SizedBox(height: 24),

              // School & Class Details
              _buildSectionTitle('School & Class Details'),
              const SizedBox(height: 8),
              _buildInfoRow('Address', student.address ?? 'Not available'),
              _buildInfoRow('Class', student.className ?? 'Not available'),
              _buildInfoRow('Section', student.section ?? 'Not available'),
              _buildInfoRow(
                'Class Teacher',
                student.classTeacherName ?? 'Not available',
              ),
              _buildInfoRow(
                'Sibling in School',
                student.hasSibling == true ? 'Yes' : 'No',
              ),
              _buildInfoRow('Transport', student.transport ?? 'Not available'),
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
