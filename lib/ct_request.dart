import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting the date/time

class CTRequestPage extends StatefulWidget {
  @override
  _CTRequestPageState createState() => _CTRequestPageState();
}

class _CTRequestPageState extends State<CTRequestPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? course, semester;

  @override
  void initState() {
    super.initState();
    _fetchClassTeacherDetails();
  }

  // Fetch class teacher's course and semester
  Future<void> _fetchClassTeacherDetails() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.collection('class_teachers').doc(user.email).get();
        if (userData.exists) {
          setState(() {
            course = userData['course'];
            semester = userData['semester'];
          });
        } else {
          print("No data found for the class teacher in Firestore.");
        }
      } else {
        print("User is not logged in.");
      }
    } catch (e) {
      print("Error fetching class teacher details: $e");
    }
  }

  // Update request status (approve or reject)
  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
        'approved_by_class_teacher': status == 'approved',
      });

      if (status == 'approved') {
        // Forward to HOD
        await _firestore.collection('requests').doc(requestId).update({
          'approved_by_hod': false, // HOD approval pending
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status!")));
    } catch (e) {
      print("Error updating request status: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  // Fetch requests for the class teacher's course and semester
  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    try {
      if (course == null || semester == null) {
        print("Course or semester is null, returning empty list.");
        return [];
      }

      final snapshot = await _firestore
          .collection('requests')
          .where('course', isEqualTo: course)
          .where('semester', isEqualTo: semester)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) => {
            'request_id': doc.id,
            ...doc.data(),
          }).toList();
    } catch (e) {
      print("Error fetching requests: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Requests")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requestId = request['request_id'];
              final studentName = request['studentName'];
              final leaveType = request['leaveType'];
              final fromDate = request['fromDate'];
              final toDate = request['toDate'];
              final reason = request['reason'];
              final status = request['status'];
              final fromTime = request['fromTime']; // The time field for half-day leave
              final toTime = request['toTime']; // The time field for half-day leave

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(studentName),
                  subtitle: Builder(
                    builder: (context) {
                      if (leaveType == 'Full-Day Leave' || leaveType == 'On-Job Leave') {
                        return Text(
                          "$leaveType\nFrom: ${DateFormat.yMMMd().format(DateTime.parse(fromDate))} "
                          "To: ${DateFormat.yMMMd().format(DateTime.parse(toDate))}\n"
                          "Reason: $reason\nStatus: $status",
                        );
                      } else if (leaveType == 'Half-Day Leave') {
                        String fromTimeFormatted =
                            fromTime != null ? DateFormat.jm().format(DateTime.parse(fromTime)) : 'Not specified';
                        String toTimeFormatted =
                            toTime != null ? DateFormat.jm().format(DateTime.parse(toTime)) : 'Not specified';

                        return Text(
                          "$leaveType\nFrom: $fromTimeFormatted To: $toTimeFormatted\n"
                          "Reason: $reason\nStatus: $status",
                        );
                      } else {
                        return Text("Invalid leave type");
                      }
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _updateRequestStatus(requestId, 'approved'),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _updateRequestStatus(requestId, 'rejected'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
