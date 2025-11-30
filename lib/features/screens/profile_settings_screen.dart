import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String currentProfileImage;
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final String currentAge;
  final String currentWeight;
  final String currentHeight;

  const ProfileSettingsScreen({
    super.key,
    required this.currentProfileImage,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    required this.currentAge,
    required this.currentWeight,
    required this.currentHeight,
  });

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String? _profileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profileImage = widget.currentProfileImage;
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _ageController = TextEditingController(text: widget.currentAge);
    _weightController = TextEditingController(text: widget.currentWeight);
    _heightController = TextEditingController(text: widget.currentHeight);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile.path;
      });
    }
  }

  void _saveProfile() {
    Navigator.pop(context, {
      'image': _profileImage,
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'age': _ageController.text,
      'weight': _weightController.text,
      'height': _heightController.text,
    });
  }

  Widget _buildTextField(
      {required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage!.startsWith('assets/')
                    ? AssetImage(_profileImage!) as ImageProvider
                    : FileImage(File(_profileImage!)),
              ),
            ),
            const SizedBox(height: 12),

            _buildTextField(label: 'Name', controller: _nameController),
            _buildTextField(label: 'Email', controller: _emailController),
            _buildTextField(label: 'Phone', controller: _phoneController),
            _buildTextField(label: 'Age', controller: _ageController),
            _buildTextField(label: 'Weight (kg)', controller: _weightController),
            _buildTextField(label: 'Height (cm)', controller: _heightController),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}