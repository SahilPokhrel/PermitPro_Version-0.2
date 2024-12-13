import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      if (user == null) {
        print("User is not logged in.");
        return;
      }

      final userData = await _firestore.collection('class_teachers').doc(user.email).get();
      if (userData.exists) {
        setState(() {
          course = userData['course'];
          semester = userData['semester'];
        });
      } else {
        print("No data found for the class teacher in Firestore.");
      }
    } catch (e) {
      print("Error fetching class teacher details: $e");
    }
  }

  // Log the action in the classTeacherHistory collection
  Future<void> _logActionInHistory(String requestId, String status, String teacherEmail) async {
    try {
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (requestDoc.exists) {
        final requestData = requestDoc.data() ?? {};
        await _firestore.collection('classTeacherHistory').add({
          'request_id': requestId,
          'studentName': requestData['studentName'] ?? 'Unknown',
          'leaveType': requestData['leaveType'] ?? 'Unknown',
          'status': status == 'approved' ? 'Approved by Class Teacher' : 'Rejected by Class Teacher',
          'approvedBy': teacherEmail,
          'timestamp': FieldValue.serverTimestamp(), // Record the time of action
        });
      }
    } catch (e) {
      print("Error logging action in history: $e");
    }
  }

  // Update request status, log action in history, and forward to HOD
  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        print("User not logged in or email is null");
        return;
      }

      // Log the action in classTeacherHistory
      await _logActionInHistory(requestId, status, user.email!);  // Add ! to assert email is not null

      if (status == 'rejected') {
        // Directly reject the request and update the status
        await _firestore.collection('requests').doc(requestId).update({
          'status': 'Rejected by Class Teacher',
          'approved_by_class_teacher': false, // Mark as rejected by class teacher
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request rejected")),
        );
      } else if (status == 'approved') {
        // If approved, update the status and forward it to the HOD
        await _firestore.collection('requests').doc(requestId).update({
          'status': 'Approved by Class Teacher',
          'approved_by_class_teacher': true,
        });

        // Fetch HOD email for the respective course
        final hodSnapshot = await _firestore.collection('hods').where('course', isEqualTo: course).get();
        if (hodSnapshot.docs.isNotEmpty) {
          final hodEmail = hodSnapshot.docs.first['email'];

          // Forward the request to the HOD
          await _firestore.collection('hod_requests').doc(requestId).set({
            ...await _firestore.collection('requests').doc(requestId).get().then((doc) => doc.data() ?? {}),
            'hod_email': hodEmail,
            'approved_by_hod': false, // Initially set to false
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request forwarded to HOD")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("HOD for the course not found!")),
          );
        }
      }
    } catch (e) {
      print("Error updating request status: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  // Fetch requests for the class teacher's course and semester
  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    try {
      if (course == null || semester == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('requests')
          .where('course', isEqualTo: course)
          .where('semester', isEqualTo: semester)
          .where('status', isEqualTo: 'Pending')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'request_id': doc.id,
          'studentName': data['studentName'] ?? 'Not specified',
          'leaveType': data['leaveType'] ?? 'Not specified',
          'fromDate': data['fromDate'] ?? '',
          'toDate': data['toDate'] ?? '',
          'reason': data['reason'] ?? 'Not specified',
          'phone': data['phone'] ?? 'Not specified',
          'parentPhone': data['parentPhone'] ?? 'Not specified',
          'usn': data['usn'] ?? 'Not specified',
          'semester': data['semester'] ?? 'Not specified',
          'attachment': data['attachment'] ?? '',
        };
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
              final leaveDetails = request['leaveType'] == 'Half-Day Leave'
                  ? "From Time: ${request['fromTime']}\nTo Time: ${request['toTime']}"
                  : "From Date: ${request['fromDate']}\nTo Date: ${request['toDate']}";

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(request['studentName']),
                      subtitle: Text(
                        "USN: ${request['usn']}\n"
                        "Semester: ${request['semester']}\n"
                        "Leave Type: ${request['leaveType']}\n"
                        "$leaveDetails\n"
                        "Reason: ${request['reason']}\n"
                        "Phone: ${request['phone']}\n"
                        "Parent's Phone: ${request['parentPhone']}",
                      ),
                      trailing: request['attachment'].isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.download, color: Colors.blue),
                              onPressed: () {
                                // Handle attachment download (if needed)
                              },
                            )
                          : null,
                      isThreeLine: true,
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateRequestStatus(request['request_id'], 'approved'),
                          child: Text("Approve"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateRequestStatus(request['request_id'], 'rejected'),
                          child: Text("Reject"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
