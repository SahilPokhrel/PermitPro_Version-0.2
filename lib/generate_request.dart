import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GenerateRequest extends StatefulWidget {
  @override
  _GenerateRequestState createState() => _GenerateRequestState();
}

class _GenerateRequestState extends State<GenerateRequest> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedLeaveType;
  DateTime? fromDate;
  DateTime? toDate;
  String? reason;
  File? attachmentFile;

  // Student details
  String? name, email, course, usn, phone, parentPhone, semester;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('students').doc(user.email).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            name = data?['fullName'];
            email = data?['email'];
            course = data?['course'];
            usn = data?['usn'];
            phone = data?['phone'];
            parentPhone = data?['parentPhone'];
            semester = data?['semester'];
          });
        }
      }
    } catch (e) {
      print("Error fetching student details: $e");
    }
  }

  Future<bool> hasActiveRequest(String email) async {
    final querySnapshot = await _firestore
        .collection('requests')
        .where('email', isEqualTo: email)
        .where('status', whereNotIn: ['Rejected by Class-Teacher', 'Rejected by HOD', 'Approved by HOD'])
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = _auth.currentUser;

        if (user != null) {
          final hasActive = await hasActiveRequest(user.email!);
          if (hasActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You already have an active request!")),
            );
            return;
          }

          await _firestore.collection('requests').add({
            'studentName': name,
            'email': email,
            'course': course,
            'usn': usn,
            'phone': phone,
            'parentPhone': parentPhone,
            'semester': semester,
            'leaveType': selectedLeaveType,
            'fromDate': selectedLeaveType != "Half-Day Leave" ? fromDate?.toIso8601String() : null,
            'toDate': selectedLeaveType != "Half-Day Leave" ? toDate?.toIso8601String() : null,
            'reason': reason,
            'attachment': attachmentFile != null ? attachmentFile!.path : null,
            'status': 'Pending',
            'approved_by_class_teacher': false,
            'approved_by_hod': false,
            'submittedAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request submitted successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error submitting request: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit request.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields.")),
      );
    }
  }

  Future<void> _pickAttachment() async {
    final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        attachmentFile = File(file.path);
      });
    }
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      setState(() {
        fromDate = range.start;
        toDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Request"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: selectedLeaveType,
                items: ['Full-Day Leave', 'Half-Day Leave', 'On-Job Leave']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLeaveType = value;
                    fromDate = null;
                    toDate = null;
                  });
                },
                decoration: const InputDecoration(labelText: "Leave Type"),
                validator: (value) => value == null ? "Please select a leave type" : null,
              ),
              if (selectedLeaveType == "Full-Day Leave" || selectedLeaveType == "On-Job Leave")
                ListTile(
                  title: const Text("Select Date Range"),
                  subtitle: Text(
                      fromDate == null || toDate == null
                          ? "Not selected"
                          : "${fromDate!.toLocal().toString().split(' ')[0]} - ${toDate!.toLocal().toString().split(' ')[0]}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateRange,
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Reason"),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? "Reason is required" : null,
                onChanged: (value) {
                  reason = value;
                },
              ),
              ListTile(
                title: const Text("Attach Document"),
                subtitle: Text(attachmentFile == null ? "No file selected" : "File selected"),
                trailing: const Icon(Icons.attach_file),
                onTap: _pickAttachment,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
