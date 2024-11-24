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
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
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
        .where('status', whereIn: [
          'Pending',
          'Approved by Class-Teacher',
          'Rejected by Class-Teacher'
        ])
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _checkAndMoveTimeouts() async {
    final querySnapshot = await _firestore
        .collection('requests')
        .where('email', isEqualTo: email)
        .get();

    final now = DateTime.now();

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final submittedAt = (data['submittedAt'] as Timestamp).toDate();

      // Check if the request is older than 3 hours
      if (now.difference(submittedAt).inHours >= 3 && data['status'] == 'Pending') {
        // Move the request to the "history" collection
        await _firestore.collection('history').add(data);
        await _firestore.collection('requests').doc(doc.id).delete();
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() &&
        (selectedLeaveType != "On-Job Leave" || attachmentFile != null)) {
      try {
        final User? user = _auth.currentUser;

        if (user != null) {
          // Check if the user has any active requests
          final hasActive = await hasActiveRequest(user.email!);

          if (hasActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You already have an active request!"),
              ),
            );
            return;
          }

          // Generate a unique request ID, for example using current timestamp
          String requestId = DateTime.now().millisecondsSinceEpoch.toString();

          // Create the request document
          await _firestore.collection('requests').add({
            'request_id': requestId, // Unique request ID
            'studentName': name,
            'email': email,
            'course': course,
            'usn': usn,
            'phone': phone,
            'parentPhone': parentPhone,
            'semester': semester,
            'leaveType': selectedLeaveType,
            'fromDate': fromDate?.toIso8601String(),
            'toDate': toDate?.toIso8601String(),
            'fromTime': fromTime != null ? fromTime!.format(context) : null,
            'toTime': toTime != null ? toTime!.format(context) : null,
            'reason': reason,
            'attachment': attachmentFile != null ? attachmentFile!.path : null,
            'status': 'Pending', // Default status is pending
            'approved_by_class_teacher': false, // Initially false
            'approved_by_hod': false, // Initially false
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

  Future<void> _pickTimeRange() async {
    final TimeOfDay? startTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (startTime != null) {
      final TimeOfDay? endTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (endTime != null) {
        setState(() {
          fromTime = startTime;
          toTime = endTime;
        });
      }
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
                    fromTime = null;
                    toTime = null;
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
                          : "${fromDate!.toLocal()} - ${toDate!.toLocal()}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateRange,
                ),
              if (selectedLeaveType == "Half-Day Leave")
                ListTile(
                  title: const Text("Select Time Range"),
                  subtitle: Text(
                      fromTime == null || toTime == null
                          ? "Not selected"
                          : "${fromTime!.format(context)} - ${toTime!.format(context)}"),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTimeRange,
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
              if (selectedLeaveType == "On-Job Leave" && attachmentFile == null)
                const Text(
                  "Attachment is required for On-Job Leave",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _checkAndMoveTimeouts();
                  await _submitRequest();
                },
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
