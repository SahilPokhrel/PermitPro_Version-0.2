import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'qr.dart'; // Import the QRPage

class CheckStatus extends StatelessWidget {
  const CheckStatus({Key? key}) : super(key: key);

  // Fetch student requests from Firestore based on the current user's email
  Stream<QuerySnapshot> _fetchStudentRequests() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('requests')
        .where('email', isEqualTo: user.email)
        .snapshots();
  }

  // Format the date range for full-day and on-job leave requests
  String _formatDateRange(DateTime from, DateTime to) {
    return "${DateFormat.yMMMd().format(from)} - ${DateFormat.yMMMd().format(to)}";
  }

  // Parse Firestore date fields to DateTime
  DateTime? _parseDate(dynamic dateField) {
    if (dateField is Timestamp) {
      return dateField.toDate();
    } else if (dateField is String) {
      try {
        return DateFormat.yMMMd().parse(dateField);
      } catch (e) {
        print("Error parsing date string: $e");
        return null;
      }
    }
    return null;
  }

  // Move a request to the history collection
  Future<void> _moveToHistory(String requestId, Map<String, dynamic> requestData, BuildContext context) async {
    try {
      // Add the request to the history collection
      await FirebaseFirestore.instance
          .collection('studentHistory')
          .doc(requestId)
          .set(requestData);

      // Delete the request from the active requests collection
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();

      // Provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request moved to history successfully.")),
      );
      print("Request moved to history successfully.");
    } catch (e) {
      print("Error moving request to history: $e");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to move request to history. Please try again.")),
      );
    }
  }

  // Navigate to QR page
  void _navigateToQRCodePage(BuildContext context, Map<String, dynamic> requestData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRPage(requestData: requestData), // Passing data to QRPage
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Check Status"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchStudentRequests(),
        builder: (context, snapshot) {
          // Show loading indicator while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors if any
          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }

          // Handle empty state if no data found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No leave requests found"));
          }

          final requests = snapshot.data!.docs;

          // Reverse the list of requests to show the latest ones first
          final reversedRequests = requests.reversed.toList();

          return ListView.builder(
            itemCount: reversedRequests.length,
            itemBuilder: (context, index) {
              final request = reversedRequests[index];
              final requestData = request.data() as Map<String, dynamic>;
              final leaveType = requestData['leaveType'];
              final reason = requestData['reason'];
              final status = requestData['status'];
              final requestId = request.id;

              DateTime? fromDate;
              DateTime? toDate;

              // Parse fromDate and toDate if the leave type is Full-Day Leave or On-Job Leave
              if (leaveType == 'Full-Day Leave' || leaveType == 'On-Job Leave') {
                final fromDateField = requestData['fromDate'];
                final toDateField = requestData['toDate'];
                fromDate = _parseDate(fromDateField);
                toDate = _parseDate(toDateField);
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Leave Type: $leaveType",
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      leaveType == 'Full-Day Leave' || leaveType == 'On-Job Leave'
                          ? Text(
                              "Date: ${fromDate != null && toDate != null ? _formatDateRange(fromDate, toDate!) : 'N/A'}",
                              style: TextStyle(fontSize: 14.0),
                            )
                          : Text("Date: N/A", style: TextStyle(fontSize: 14.0)),
                      SizedBox(height: 8.0),
                      Text("Reason: $reason", style: TextStyle(fontSize: 14.0)),
                      SizedBox(height: 8.0),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: status == 'rejected' ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      // Replace the delete button with the move to history functionality
                      ElevatedButton(
                        onPressed: () {
                          _moveToHistory(requestId, requestData, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text("Delete & Move to History"),
                      ),
                      if (status == 'Approved by HOD' && requestData['approved_by_hod'] == true) ...[
                        ElevatedButton(
                          onPressed: () {
                            _navigateToQRCodePage(context, requestData);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: Text("Get QR"),
                        ),
                      ],
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
