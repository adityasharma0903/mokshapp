import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/data_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _fatherEmailController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _currentAddressController =
      TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedTransport;
  bool _hasSibling = false;
  PlatformFile? _selectedPhoto;

  List<Map<String, dynamic>> _teachers = [];
  String? _selectedTeacherId; // New state variable for teacher ID
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId; // New state variable for class ID

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _transports = ['Bus', 'Self', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final teachersResponse = await _dataService.get('teachers');
    final classesResponse = await _dataService.get('classes');

    if (teachersResponse is List && classesResponse is List) {
      setState(() {
        _teachers = List<Map<String, dynamic>>.from(teachersResponse);
        _classes = List<Map<String, dynamic>>.from(classesResponse);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load classes and teachers.')),
      );
    }
  }

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

  void _saveStudent() async {
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

      final studentData = {
        'name': _nameController.text,
        'roll_number': _rollNumberController.text,
        'email': _fatherEmailController.text,
        'password_hash': _passwordController.text,
        'user_type': 'student',
        'dob': _selectedDateOfBirth?.toIso8601String(),
        'gender': _selectedGender,
        'nationality': _nationalityController.text,
        'religion': _religionController.text,
        'blood_group': _bloodGroupController.text,
        'father_name': _fatherNameController.text,
        'mother_name': _motherNameController.text,
        'contact_number': _contactNumberController.text,
        'permanent_address': _permanentAddressController.text,
        'current_address': _currentAddressController.text,
        'father_email': _fatherEmailController.text,
        'transport_acquired': _selectedTransport,
        'has_sibling': _hasSibling,
        'class_id': _selectedClassId,
        'class_teacher_id': _selectedTeacherId,
        'photograph_url': _selectedPhoto != null ? _selectedPhoto!.name : null,
      };

      final response = await _dataService.post('students/add', studentData);

      if (response['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
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
    _rollNumberController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _bloodGroupController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _fatherEmailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
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
    final classItems = _classes.map((cls) {
      return DropdownMenuItem(
        value: cls['class_id'] as String,
        child: Text('${cls['class_name']} - ${cls['section']}'),
      );
    }).toList();

    final teacherItems = _teachers.map((teacher) {
      return DropdownMenuItem(
        value: teacher['teacher_id'] as String,
        child: Text(teacher['name'] as String),
      );
    }).toList();

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
              // --- Personal Information Section ---
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
                controller: _rollNumberController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
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
                items: _genders.map((String gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedGender = newValue),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _religionController,
                decoration: const InputDecoration(
                  labelText: 'Religion',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // --- Family Information Section ---
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
                controller: _fatherEmailController,
                decoration: const InputDecoration(
                  labelText: 'Father\'s Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // --- Class & School Details Section ---
              _buildSectionTitle('Class & School Details'),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Class/Section',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClassId,
                items: classItems,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClassId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Class Teacher',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTeacherId,
                items: teacherItems,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTeacherId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Sibling in same school?'),
                value: _hasSibling,
                onChanged: (bool? value) =>
                    setState(() => _hasSibling = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Transport Acquired',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTransport,
                items: _transports.map((String transport) {
                  return DropdownMenuItem(
                    value: transport,
                    child: Text(transport),
                  );
                }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedTransport = newValue),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera, color: AppColors.primary),
                label: const Text(
                  'Upload Photograph',
                  style: TextStyle(color: AppColors.primary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
}
