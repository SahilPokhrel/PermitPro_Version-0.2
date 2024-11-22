import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'stu_dashboard.dart';
import 'hod_dashboard.dart'; // Corrected file name for HOD Dashboard
import 'ct_dashboard.dart'; // Correct file name for Class-Teacher Dashboard

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

  String _selectedRole = 'Student'; // Default selected role
  XFile? _profileImage;
  static const String hodCode = "123456"; // Updated from "adminCode"

  // Text controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usnController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _hodCodeController = TextEditingController(); // Renamed field for HOD
  final TextEditingController _classTeacherCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    } else if (_selectedRole == 'HOD') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HODDashboard()));
    } else if (_selectedRole == 'Class-Teacher') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ClassTeacherDashboard()));
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
      if (_selectedRole == "HOD" && _hodCodeController.text != hodCode) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid HOD Code. Please enter the correct code.")));
        return;
      }

      try {
        // Base profile data for all roles
        final profileData = {
          "email": _emailController.text,
          "fullName": _nameController.text,
          "phone": _phoneController.text,
          "role": _selectedRole,
          "profileImage": await _uploadProfileImage(), // Add image URL if available
        };

        // Additional data based on selected role
        if (_selectedRole == "Student") {
          profileData.addAll({
            "parentPhone": _parentPhoneController.text,
            "address": _addressController.text,
            "usn": _usnController.text,
            "college": "T John Group of Institutions",
            "course": "BE Computer Science & Eng",
            "semester": "Semester 1"
          });
        } else if (_selectedRole == "HOD") {
          profileData.addAll({
            "staffId": _staffIdController.text,
            "hodCode": _hodCodeController.text,
            "college": "T John Group of Institutions",
            "course": "BE Computer Science & Eng"
          });
        } else if (_selectedRole == "Class-Teacher") {
          profileData.addAll({
            "staffId": _staffIdController.text,
            "classTeacherCode": _classTeacherCodeController.text,
            "college": "T John Group of Institutions",
            "course": "BE Computer Science & Eng"
          });
        }

        // Save profile data to Firestore
        final collectionName = _selectedRole == "Student"
            ? "students"
            : (_selectedRole == "HOD" ? "hods" : "class_teachers");
        await _firestore
            .collection(collectionName)
            .doc(_emailController.text)
            .set(profileData);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile created successfully!")));
        _navigateToDashboard();
      } catch (e) {
        print("Error saving profile data: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to save profile data: ${e.toString()}")));
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage == null
                      ? AssetImage('assets/default_profile.jpg') as ImageProvider
                      : FileImage(File(_profileImage!.path)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            _buildTextField("Email", _emailController, isEmail: true),
            DropdownButton<String>(
              value: _selectedRole,
              items: <String>['Student', 'HOD', 'Class-Teacher'].map((String value) {
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
                : _selectedRole == 'HOD'
                    ? _buildHODForm()
                    : _buildClassTeacherForm(),
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
          ElevatedButton(onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }

  Widget _buildHODForm() {
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
          _buildTextField("HOD Code", _hodCodeController, isMandatory: true),
          SizedBox(height: 20.0),
          ElevatedButton(onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }

  Widget _buildClassTeacherForm() {
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
          _buildTextField("Class Teacher Code", _classTeacherCodeController, isMandatory: true),
          SizedBox(height: 20.0),
          ElevatedButton(onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isEmail = false, bool isMandatory = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: isMandatory
          ? (value) => value == null || value.isEmpty
              ? 'Please enter $label'
              : null
          : null,
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
          return 'Invalid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
