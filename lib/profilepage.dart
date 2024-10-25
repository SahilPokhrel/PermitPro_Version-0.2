import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'stu_dashboard.dart';
import 'admin_dashboard.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  ProfilePage({required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final picker = ImagePicker();

  String _selectedRole = 'Student';
  XFile? _profileImage;

  // Text controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usnController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the email field with the email passed from the previous screen
    _emailController.text = widget.email;
  }

  void _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profileImage = pickedFile;
    });
  }

  Future<void> _navigateToDashboard() async {
    if (_selectedRole == 'Student') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => StudentDashboard()));
    } else if (_selectedRole == 'Admin') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminDashboard()));
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    try {
      final filePath = 'profile_images/${widget.email}.jpg';
      final fileRef = _storage.ref().child(filePath);
      await fileRef.putFile(File(_profileImage!.path));
      return await fileRef.getDownloadURL();
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Ensure the email is not empty
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Email cannot be empty.")));
        return;
      }

      try {
        // Prepare profile data with user input
        final profileData = {
          "email": _emailController.text,
          "fullName": _nameController.text,
          "phone": _phoneController.text,
          "parentPhone": _parentPhoneController.text,
          "address": _addressController.text,
          "usn": _usnController.text,
          "staffId": _staffIdController.text,
          "adminCode": _adminCodeController.text,
          "role": _selectedRole,
        };

        // Upload profile image and get URL
        final imageUrl = await _uploadProfileImage();
        if (imageUrl != null) {
          profileData["profileImage"] =
              imageUrl; // Add image URL to profile data
        }

        final collectionName =
            _selectedRole == "Student" ? "students" : "admins";

        // Save data in Firestore
        await _firestore
            .collection(collectionName)
            .doc(_emailController.text) // Ensure email is used as document ID
            .set(profileData);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile created successfully!")));
        _navigateToDashboard();
      } catch (e) {
        print("Error saving profile data: ${e.toString()}"); // Detailed logging
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Failed to save profile data: ${e.toString()}"))); // Show detailed error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Your Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage == null
                    ? AssetImage('assets/default_profile.jpg') as ImageProvider
                    : FileImage(File(_profileImage!.path)) as ImageProvider,
              ),
            ),
            SizedBox(height: 16.0),
            // Email field
            _buildTextField("Email", _emailController, isEmail: true),
            DropdownButton<String>(
              value: _selectedRole,
              items: <String>['Student', 'Admin'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
            _selectedRole == 'Student'
                ? _buildStudentForm()
                : _buildAdminForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTextField("Full Name", _nameController),
          _buildPhoneField("Phone No.", _phoneController),
          _buildPhoneField("Parent Mob No.", _parentPhoneController),
          _buildTextField("Address", _addressController),
          _buildDropdown("College", ["T John Group of Institutions"], (val) {}),
          _buildDropdown(
              "Course",
              [
                "BE Computer Science & Eng",
                "BE Information Science & Eng",
                "BE Data Science",
                "BE Electronics & Electrical Eng",
                "BE Electronics & Communication Eng",
                "BE Civil Eng",
                "BE IoT"
              ],
              (val) {}),
          _buildDropdown(
              "Semester",
              [
                "Semester 1",
                "Semester 2",
                "Semester 3",
                "Semester 4",
                "Semester 5",
                "Semester 6",
                "Semester 7",
                "Semester 8"
              ],
              (val) {}),
          _buildTextField("USN", _usnController),
          SizedBox(height: 20.0),
          ElevatedButton(
              onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTextField("Full Name", _nameController),
          _buildPhoneField("Phone No.", _phoneController),
          _buildDropdown("College", ["T John Group of Institutions"], (val) {}),
          _buildDropdown(
              "Course",
              [
                "BE Computer Science & Eng",
                "BE Information Science & Eng",
                "BE Data Science",
                "BE Electronics & Electrical Eng",
                "BE Electronics & Communication Eng",
                "BE Civil Eng",
                "BE IoT"
              ],
              (val) {}),
          _buildTextField("Staff ID", _staffIdController),
          _buildTextField("Admin Code", _adminCodeController),
          SizedBox(height: 20.0),
          ElevatedButton(
              onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(String labelText, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: TextInputType.phone,
      validator: (value) => value == null || value.length != 10
          ? 'Please enter a valid 10-digit phone number'
          : null,
    );
  }

  Widget _buildDropdown(
      String labelText, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: labelText),
      items: options
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a $labelText' : null,
    );
  }
}
