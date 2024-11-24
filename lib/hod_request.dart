import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting the date/time

class HodRequestPage extends StatefulWidget {
  @override
  _HodRequestPageState createState() => _HodRequestPageState();
}

class _HodRequestPageState extends State<HodRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _requestsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = _firestore.collection('requests')
        .where('approved_by_class_teacher', isEqualTo: true) // Only show requests approved by class teacher
        .where('approved_by_hod', isEqualTo: false) // Only show requests pending HOD approval
        .orderBy('fromDate') // Sort by the leave start date
        .snapshots();
  }

  // Approve or Reject a request
  Future<void> _updateRequestStatus(String requestId, bool isApproved) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update the request status in Firestore
      await _firestore.collection('requests').doc(requestId).update({
        'approved_by_hod': isApproved,
        'status': isApproved ? 'Approved by HOD' : 'Rejected by HOD',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isApproved ? "Request approved" : "Request rejected")),
      );
    } catch (e) {
      print("Error updating request status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update request status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HOD Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading requests"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!.docs;

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

              // Convert the fromDate and toDate to DateTime objects
              DateTime fromDateTime = DateTime.parse(fromDate);
              DateTime toDateTime = DateTime.parse(toDate);

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(studentName),
                  subtitle: Text(
                    "$leaveType - From: ${DateFormat.yMMMd().format(fromDateTime)} To: ${DateFormat.yMMMd().format(toDateTime)}\nReason: $reason\nStatus: $status"
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _updateRequestStatus(requestId, true), // Approve
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _updateRequestStatus(requestId, false), // Reject
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
