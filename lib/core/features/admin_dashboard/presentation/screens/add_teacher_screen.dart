import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/data_service.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _currentAddressController =
      TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedNationality;
  String? _selectedBloodGroup;
  PlatformFile? _selectedPhoto;

  final List<String> _genders = ['Male', 'Female', 'Other'];
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

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _pickPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _selectedPhoto = result.files.first;
      });
    }
  }

  void _saveTeacher() async {
    if (_formKey.currentState!.validate()) {
      // if (_selectedPhoto == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Please upload a passport-size photograph.'),
      //       backgroundColor: AppColors.error,
      //     ),
      //   );
      //   return;
      // }

      final teacherData = {
        'email': _emailController.text,
        'password_hash': _passwordController.text,
        'user_type': 'teacher',
        'name': _fullNameController.text,
        'dob': _selectedDateOfBirth?.toIso8601String(),
        'gender': _selectedGender,
        'marital_status': _selectedMaritalStatus,
        'nationality': _selectedNationality,
        'blood_group': _selectedBloodGroup,
        'contact_number': _contactNumberController.text,
        'permanent_address': _permanentAddressController.text,
        'current_address': _currentAddressController.text,
        'spouse_name': _spouseNameController.text,
        'designation': _designationController.text,
        'photograph_url': _selectedPhoto != null ? _selectedPhoto!.name : null,
      };

      final response = await _dataService.post('teachers/add', teacherData);

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher added successfully!'),
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
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _spouseNameController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
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
        title: const Text('Add New Teacher'),
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
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (as per ID)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Set Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
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
                      ? 'Date of Birth'
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
                onChanged: (String? newValue) =>
                    setState(() => _selectedGender = newValue),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                ),
                value: _selectedMaritalStatus,
                items: _maritalStatuses
                    .map(
                      (String status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedMaritalStatus = newValue),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  border: OutlineInputBorder(),
                ),
                value: _selectedNationality,
                items: _nationalities
                    .map(
                      (String nationality) => DropdownMenuItem(
                        value: nationality,
                        child: Text(nationality),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedNationality = newValue),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBloodGroup,
                items: _bloodGroups
                    .map(
                      (String bg) =>
                          DropdownMenuItem(value: bg, child: Text(bg)),
                    )
                    .toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedBloodGroup = newValue),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Contact Information'),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _permanentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Permanent Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Current Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Family Information'),
              TextFormField(
                controller: _fatherNameController,
                decoration: const InputDecoration(
                  labelText: 'Father’s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                  labelText: 'Mother’s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spouseNameController,
                decoration: const InputDecoration(
                  labelText: 'Spouse’s Name (if applicable)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Professional Information'),
              TextFormField(
                controller: _designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  print('Academic qualifications upload clicked');
                },
                icon: const Icon(
                  Icons.upload_file,
                  color: AppColors.textPrimary,
                ),
                label: const Text(
                  'Upload Academic Qualifications',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  print('Professional qualifications upload clicked');
                },
                icon: const Icon(
                  Icons.upload_file,
                  color: AppColors.textPrimary,
                ),
                label: const Text(
                  'Upload Professional Qualifications',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Photograph'),
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera, color: AppColors.primary),
                label: const Text('Upload Photograph'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_selectedPhoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected Photo: ${_selectedPhoto!.name}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Teacher',
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
