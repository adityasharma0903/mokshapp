import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/models/teacher.dart';
import '../../../../../core/services/data_service.dart';

class TeacherEditScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherEditScreen({super.key, required this.teacher});

  @override
  State<TeacherEditScreen> createState() => _TeacherEditScreenState();
}

class _TeacherEditScreenState extends State<TeacherEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _designationController;

  // New controllers for the enhanced fields
  late TextEditingController _contactController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _currentAddressController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _spouseNameController;

  // State variables for dropdowns
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedMaritalStatus;
  String? _selectedNationality;
  String? _selectedBloodGroup;
  String? _selectedDepartment;

  // Mock data for dropdowns
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
  ];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];
  final List<String> _nationalities = ['Indian', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher.name);
    _emailController = TextEditingController(text: widget.teacher.email);
    _designationController = TextEditingController(
      text: widget.teacher.designation,
    );

    _contactController = TextEditingController(
      text: widget.teacher.contactNumber,
    );
    _permanentAddressController = TextEditingController(
      text: widget.teacher.permanentAddress,
    );
    _currentAddressController = TextEditingController(
      text: widget.teacher.currentAddress,
    );
    _fatherNameController = TextEditingController(
      text: widget.teacher.fatherName,
    );
    _motherNameController = TextEditingController(
      text: widget.teacher.motherName,
    );
    _spouseNameController = TextEditingController(
      text: widget.teacher.spouseName,
    );

    _selectedGender = widget.teacher.gender;
    _selectedDateOfBirth = widget.teacher.dob;
    _selectedMaritalStatus = widget.teacher.maritalStatus;
    _selectedNationality = widget.teacher.nationality;
    _selectedBloodGroup = widget.teacher.bloodGroup;
    _selectedDepartment = widget
        .teacher
        .designation; // Assuming designation is also the department
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1985, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedTeacherData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'designation': _designationController.text,
        'contact_number': _contactController.text,
        'permanent_address': _permanentAddressController.text,
        'current_address': _currentAddressController.text,
        'father_name': _fatherNameController.text,
        'mother_name': _motherNameController.text,
        'spouse_name': _spouseNameController.text,
        'gender': _selectedGender,
        'dob': _selectedDateOfBirth?.toIso8601String(),
        'marital_status': _selectedMaritalStatus,
        'nationality': _selectedNationality,
        'blood_group': _selectedBloodGroup,
      };

      final response = await _dataService.put(
        'teachers/edit/${widget.teacher.id}',
        updatedTeacherData,
      );

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher details updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _contactController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _spouseNameController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Teacher Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildSectionTitle('Personal Information'),
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
                controller: _designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGender,
                items: _genders
                    .map(
                      (String gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedGender = newValue);
                },
              ),
              const SizedBox(height: 16),
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
              _buildSectionTitle('Contact & Address'),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _permanentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Permanent Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Current Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Family Information'),
              TextFormField(
                controller: _fatherNameController,
                decoration: const InputDecoration(
                  labelText: 'Father\'s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                  labelText: 'Mother\'s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spouseNameController,
                decoration: const InputDecoration(
                  labelText: 'Spouse\'s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
