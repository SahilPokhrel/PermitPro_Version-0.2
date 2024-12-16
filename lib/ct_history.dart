import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CTHistoryPage extends StatefulWidget {
  @override
  _CTHistoryPageState createState() => _CTHistoryPageState();
}

class _CTHistoryPageState extends State<CTHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    _fetchRequests(); // Directly fetch class teacher history
  }

  Future<void> _fetchRequests() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print("Fetching class teacher history for user: ${user.email}");

        // Fetch requests from the 'classTeacherHistory' collection where the class teacher's email matches
        QuerySnapshot snapshot = await _firestore
            .collection('classTeacherHistory')
            .where('approvedBy', isEqualTo: user.email) // Filter by class teacher's email
            .orderBy('timestamp', descending: true)
            .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _isLoading = false; // Stop loading if no requests are found
          });
          print("No requests found for this user.");
        } else {
          List<Map<String, dynamic>> requests = [];
          for (var doc in snapshot.docs) {
            final request = doc.data() as Map<String, dynamic>;

            // Format timestamp fields to a readable format
            String? formattedTimestamp = '';
            if (request['timestamp'] != null) {
              formattedTimestamp = (request['timestamp'] as Timestamp).toDate().toString();
            }

            // Handling nullable fields
            requests.add({
              'studentName': request['studentName'] ?? 'Unknown Student', // Add student name
              'leaveType': request['leaveType'] ?? 'Unknown Leave Type',
              'status': request['status'] ?? 'Pending',
              'fromDate': request['fromDate'] ?? 'N/A',
              'toDate': request['toDate'] ?? 'N/A',
              'reason': request['reason'] ?? 'No Reason',
              'approvedBy': request['approvedBy'] ?? 'N/A',
              'timestamp': formattedTimestamp,
            });
          }

          setState(() {
            _requests = requests;
            _isLoading = false; // Stop loading once data is fetched
          });
          print("Requests fetched successfully: ${_requests.length} records.");
        }
      }
    } catch (e) {
      print("Error fetching requests: $e");
      setState(() {
        _isLoading = false; // Stop loading in case of an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Class Teacher History"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
          : _requests.isEmpty
              ? Center(child: Text("No request history found."))
              : SingleChildScrollView( // Enable scrolling for the page content
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: _requests.map((request) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              request['studentName'] ?? 'Unknown Student', // Display student name
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Leave Type: ${request['leaveType']}"),
                                Text("Status: ${request['status']}"),
                                Text("From: ${request['fromDate']} To: ${request['toDate']}"),
                                Text("Reason: ${request['reason']}"),
                                if (request['timestamp'] != null)
                                  Text("Timestamp: ${request['timestamp']}"),
                              ],
                            ),
                            trailing: Icon(
                              request['status'] == 'Approved by Class Teacher'
                                  ? Icons.check_circle
                                  : request['status'] == 'Rejected'
                                      ? Icons.cancel
                                      : Icons.access_time,
                              color: request['status'] == 'Approved by Class Teacher'
                                  ? Colors.green
                                  : request['status'] == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
