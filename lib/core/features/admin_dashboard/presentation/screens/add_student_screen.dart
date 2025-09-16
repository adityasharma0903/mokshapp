import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();

  // New fields for enhanced UI
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedCollege;
  String? _selectedDegree;
  String? _selectedYear;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _colleges = [
    'College of Eng.',
    'College of Arts',
    'College of Science',
  ];
  final List<String> _degrees = ['BE-CSE', 'BE-IT', 'BE-ECE'];
  final List<String> _years = ['2023', '2024', '2025'];

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement the logic to save the new student details to the database

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollNumberController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Gender Selection
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: _genders
                      .map(
                        (gender) => Expanded(
                          child: RadioListTile<String>(
                            title: Text(gender),
                            value: gender,
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              ElevatedButton.icon(
                onPressed: () => _selectDateOfBirth(context),
                icon: const Icon(
                  Icons.calendar_today,
                  color: AppColors.textPrimary,
                ),
                label: Text(
                  _selectedDateOfBirth == null
                      ? 'Select Date of Birth'
                      : 'DOB: ${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Academic Info Section
              _buildSectionTitle('Academic Information'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'College',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCollege,
                items: _colleges.map((String college) {
                  return DropdownMenuItem(value: college, child: Text(college));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedCollege = newValue);
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Degree',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDegree,
                items: _degrees.map((String degree) {
                  return DropdownMenuItem(value: degree, child: Text(degree));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedDegree = newValue);
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                value: _selectedYear,
                items: _years.map((String year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedYear = newValue);
                },
                validator: (value) => value == null ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Student',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
