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
  String _userRole = ''; // To track user role
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      try {
        // Check if the user exists in the students collection
        var studentDoc = await _firestore.collection('students').doc(user.uid).get();
        if (studentDoc.exists) {
          setState(() {
            _userRole = 'Student'; // Set role to 'Student'
          });
          _fetchRequests(); // Fetch requests based on the role
          return;
        }

        // Check if the user exists in the class_teachers collection
        var classTeacherDoc = await _firestore.collection('class_teachers').doc(user.uid).get();
        if (classTeacherDoc.exists) {
          setState(() {
            _userRole = 'Class Teacher'; // Set role to 'Class Teacher'
          });
          _fetchRequests(); // Fetch requests based on the role
          return;
        }

        // Check if the user exists in the hods collection
        var hodDoc = await _firestore.collection('hods').doc(user.uid).get();
        if (hodDoc.exists) {
          setState(() {
            _userRole = 'HOD'; // Set role to 'HOD'
          });
          _fetchRequests(); // Fetch requests based on the role
          return;
        }

        // If the user is not found in any collection
        setState(() {
          _isLoading = false; // Stop loading
        });
        print("User doc does not exist in any collection.");
      } catch (e) {
        print("Error fetching user role: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  // Fetch class teacher's history (actions taken on requests) or student requests
  // Fetch class teacher's history (actions taken on requests) or student requests
  Future<void> _fetchRequests() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print("Fetching requests for user: ${user.email}");

        QuerySnapshot snapshot;

        // Only fetch class teacher history if the user is a class teacher
        if (_userRole == 'Class Teacher') {
          // Fetch requests where class teacher has approved/rejected the leave
          snapshot = await _firestore
              .collection('classTeacherHistory') // Fetch from the classTeacherHistory collection
              .where('approvedBy', isEqualTo: user.email) // Filter by class teacher's email
              .where('status', whereIn: [
                'Approved by Class Teacher',
                'Rejected by Class Teacher'
              ]) // Correct status values
              .orderBy('timestamp', descending: true)
              .get();
        } else if (_userRole == 'Student') {
          // For students, fetch their leave history from studentHistory
          snapshot = await _firestore
              .collection('studentHistory') // Assuming there is a studentHistory collection
              .where('email', isEqualTo: user.email)
              .orderBy('submittedAt', descending: true) // Use 'submittedAt' for ordering
              .get();
        } else {
          // For HOD, you may want to fetch a different collection or requests
          snapshot = await _firestore
              .collection('hodHistory') // Assuming there is a hodHistory collection
              .where('email', isEqualTo: user.email)
              .orderBy('timestamp', descending: true)
              .get();
        }

        if (snapshot.docs.isEmpty) {
          setState(() {
            _isLoading = false; // Stop loading if no requests found
          });
          print("No requests found for this user.");
        } else {
          List<Map<String, dynamic>> requests = [];
          for (var doc in snapshot.docs) {
            final request = doc.data() as Map<String, dynamic>;

            // Format timestamp fields (submittedAt, timestamp) to a readable format
            String? formattedTimestamp = '';
            if (request['timestamp'] != null) {
              formattedTimestamp = (request['timestamp'] as Timestamp).toDate().toString();
            }

            // Handling nullable fields like fromDate and toDate
            String? fromDate = request['fromDate'] != null ? request['fromDate'] : 'N/A';
            String? toDate = request['toDate'] != null ? request['toDate'] : 'N/A';

            // Add the request data
            requests.add({
              'leaveType': request['leaveType'] ?? 'Unknown Leave Type',
              'status': request['status'] ?? 'Pending',
              'fromDate': fromDate,
              'toDate': toDate,
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request History"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
            : _requests.isEmpty
                ? Center(child: Text("No request history found."))
                : ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(request['leaveType'] ?? 'Unknown Leave Type'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: ${request['status'] ?? 'Pending'}"),
                              Text("From: ${request['fromDate']} To: ${request['toDate']}"),
                              Text("Reason: ${request['reason']}"),
                              if (request['approvedBy'] != null)
                                Text("Approved By: ${request['approvedBy']}"),
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
                    },
                  ),
      ),
    );
  }
}
