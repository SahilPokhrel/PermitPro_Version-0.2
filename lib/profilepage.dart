import 'package:flutter/material.dart';
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

  String _selectedRole = 'Student'; // Default selected role
  String _selectedSemester = "Semester 1"; // Default semester value
  String _selectedCourse = "BE Information Science & Eng";

  static const String hodCode = "123456"; // Correct HOD Code
  static const String classTeacherCode = "654321"; // Correct Class-Teacher Code

  // Text controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usnController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _hodCodeController = TextEditingController();
  final TextEditingController _classTeacherCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;

    // Ensure USN input is uppercase
    _usnController.addListener(() {
      _usnController.text = _usnController.text.toUpperCase();
      _usnController.selection = TextSelection.fromPosition(
        TextPosition(offset: _usnController.text.length),
      );
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == "HOD" && _hodCodeController.text != hodCode) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Invalid HOD Code. Please enter the correct code.")));
        return;
      }

      if (_selectedRole == "Class-Teacher" &&
          _classTeacherCodeController.text != classTeacherCode) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Invalid Class-Teacher Code. Please enter the correct code.")));
        return;
      }

      try {
        if (_selectedRole == "Student") {
          // Check if account already exists with the same USN
          final studentSnapshot = await _firestore
              .collection("students")
              .where("usn", isEqualTo: _usnController.text)
              .get();

          if (studentSnapshot.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Account for USN ${_usnController.text} already exists.")));
            return; // Don't proceed with account creation if USN already exists
          }
        }

        print("Selected Course: $_selectedCourse");

        // Initialize the profileData map with common fields
        final profileData = {
          "email": _emailController.text,
          "fullName": _nameController.text,
          "phone": _phoneController.text,
          "role": _selectedRole,
        };

        // Add role-specific data to the profileData map
        if (_selectedRole == "Student") {
          profileData.addAll({
            "parentPhone": _parentPhoneController.text,
            "address": _addressController.text,
            "usn": _usnController.text,
            "college": "T John Group of Institutions",
            "course": _selectedCourse,
            "semester": _selectedSemester, // Include the semester value
          });
        } else if (_selectedRole == "HOD") {
          profileData.addAll({
            "staffId": _staffIdController.text,
            "hodCode": _hodCodeController.text,
            "college": "T John Group of Institutions",
            "course": _selectedCourse,
          });
        } else if (_selectedRole == "Class-Teacher") {
          profileData.addAll({
            "staffId": _staffIdController.text,
            "classTeacherCode": _classTeacherCodeController.text,
            "college": "T John Group of Institutions",
            "course": _selectedCourse,
            "semester": _selectedSemester, // Include the semester value
          });
        }

        // Determine the collection based on the selected role
        final collectionName = _selectedRole == "Student"
            ? "students"
            : (_selectedRole == "HOD" ? "hods" : "class_teachers");

        // Save the profile data to Firestore
        await _firestore
            .collection(collectionName)
            .doc(_emailController.text)
            .set(profileData);

        // Show success message and navigate to the dashboard
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
          _buildPhoneField("Parent's Phone No.", _parentPhoneController),
          _buildTextField("Address", _addressController),
          _buildTextField("USN", _usnController),
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
              (val) {
                setState(() {
                  _selectedCourse = val!;
                });
              }),
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
              (val) {
                setState(() {
                  _selectedSemester = val!;
                });
              }),
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
          _buildTextField("Staff ID", _staffIdController),
          _buildNumericField("HOD Code", _hodCodeController),
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
              (val) {
                setState(() {
                  _selectedCourse = val!;
                });
              }),
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
          _buildTextField("Staff ID", _staffIdController),
          _buildNumericField("Class Teacher Code", _classTeacherCodeController),
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
              (val) {
                setState(() {
                  _selectedCourse = val!;
                });
              }),
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
              (val) {
                setState(() {
                  _selectedSemester = val!;
                });
              }),
          SizedBox(height: 20.0),
          ElevatedButton(onPressed: _saveProfile, child: Text('Create Profile')),
        ],
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller,
      {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (value) {
        if (value!.isEmpty) return "$label is required";
        return null;
      },
    );
  }

  Widget _buildPhoneField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value!.isEmpty) return "$label is required";
        if (value.length != 10) return "$label should be 10 digits";
        return null;
      },
    );
  }

  Widget _buildNumericField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return "$label is required";
        return null;
      },
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}