import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/student.dart'; // Assuming path to Student model

class ChangePasswordScreen extends StatefulWidget {
  final Student student;

  const ChangePasswordScreen({super.key, required this.student});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // This function simulates the API call to update the password.
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // --- Mock API Call (Replace this with your actual DataService logic) ---
    // In a real app, you would:
    // 1. Construct a payload with widget.student.userId, currentPassword, and newPassword.
    // 2. Call your DataService.put() or DataService.post() to the appropriate backend endpoint.

    // Simulate network delay and successful response
    await Future.delayed(const Duration(seconds: 2));
    bool success = true; // Assume success for the mock

    // --- End Mock API Call ---

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully! Please log in again."),
          backgroundColor: AppColors.success,
        ),
      );
      // After a successful password change, you should ideally force a logout
      // For now, we navigate back to the profile screen.
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error: Failed to change password. Current password may be incorrect.",
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please enter your current password and set a new one.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                labelText: 'Current Password',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Current password is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                labelText: 'New Password (Min 6 characters)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'New password is required.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password Field
              _buildPasswordField(
                controller: _confirmNewPasswordController,
                labelText: 'Confirm New Password',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmation is required.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'New passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
