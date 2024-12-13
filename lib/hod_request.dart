import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HodRequestPage extends StatefulWidget {
  @override
  _HodRequestPageState createState() => _HodRequestPageState();
}

class _HodRequestPageState extends State<HodRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _requestsStream;
  String? hodCourse;

  // List to hold the request data locally
  List<DocumentSnapshot> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchHODCourse();
  }

  Future<void> _fetchHODCourse() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final hodDoc = await _firestore.collection('hods').doc(user.email).get();
      if (hodDoc.exists) {
        setState(() {
          hodCourse = hodDoc['course'];
        });

        // Update the query to listen for requests that are pending HOD approval
        _requestsStream = _firestore
            .collection('requests')
            .where('course', isEqualTo: hodCourse)
            .where('approved_by_class_teacher', isEqualTo: true)
            .orderBy('fromDate')
            .snapshots();
      } else {
        print("HOD data not found in Firestore");
      }
    } catch (e) {
      print("Error fetching HOD course: $e");
    }
  }

  Future<void> _updateRequestStatus(String requestId, bool isApproved) async {
    try {
      if (isApproved) {
        // Approve request
        await _firestore.collection('requests').doc(requestId).update({
          'approved_by_hod': true,
          'status': 'Approved by HOD',
        });
      } else {
        // Reject request
        await _firestore.collection('requests').doc(requestId).update({
          'approved_by_hod': false,
          'status': 'Rejected by HOD',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApproved ? "Request approved" : "Request rejected"),
        ),
      );
    } catch (e) {
      print("Error updating request status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update request status")),
      );
    }
  }

  // Remove the request from the UI only
  void _deleteRequest(String requestId) {
    setState(() {
      // Remove the request from the local list (UI)
      requests.removeWhere((request) => request.id == requestId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Request removed from page")),
    );
  }

  // Format date range for full-day leave
  String _formatDateRange(DateTime from, DateTime to) {
    final fromDate = DateFormat.yMMMd().format(from);
    final toDate = DateFormat.yMMMd().format(to);
    return '$fromDate to $toDate';
  }

  // Helper function to parse the date correctly
  DateTime? _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.tryParse(date);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HOD Requests"),
      ),
      body: hodCourse == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
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

                final requestsData = snapshot.data!.docs;

                // Update the local list with the snapshot data
                requests = List.from(requestsData);

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final requestId = request.id;
                    final studentName = request['studentName'];
                    final leaveType = request['leaveType'];
                    final reason = request['reason'];
                    final status = request['status'];
                    final semester = request['semester'] ?? 'N/A'; // Add semester here

                    DateTime? fromDate = _parseDate(request['fromDate']);
                    DateTime? toDate = _parseDate(request['toDate']);

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    studentName,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Chip(
                                  label: Text(leaveType),
                                  backgroundColor: Colors.blue.shade100,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            if (fromDate != null && toDate != null) ...[
                              Text(
                                "From: ${_formatDateRange(fromDate, toDate!)}",
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ] else ...[
                              Text(
                                "From: N/A",
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                            Text(
                              "Reason: $reason",
                              style: TextStyle(fontSize: 14.0),
                            ),
                            Text(
                              "Semester: $semester",  // Display semester
                              style: TextStyle(fontSize: 14.0),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              "Status: $status",
                              style: TextStyle(
                                fontSize: 14.0,
                                color: status == 'Rejected by HOD' ? Colors.red : Colors.green,
                              ),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status != 'Approved by HOD' && status != 'Rejected by HOD') ...[
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.check, color: Colors.white),
                                    label: Text("Approve"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () => _updateRequestStatus(requestId, true),
                                  ),
                                  SizedBox(width: 8.0),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.close, color: Colors.white),
                                    label: Text("Reject"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => _updateRequestStatus(requestId, false),
                                  ),
                                ],
                                if (status == 'Rejected by HOD' || status == 'Approved by HOD') ...[
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.delete, color: Colors.white),
                                    label: Text("Delete"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => _deleteRequest(requestId),  // Only remove from local list
                                  ),
                                ]
                              ],
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
