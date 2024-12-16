import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentHistory();
  }

  Future<void> _fetchStudentHistory() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('studentHistory') // Fetching from 'studentHistory' collection
            .where('email', isEqualTo: user.email)
            .orderBy('submittedAt', descending: true)
            .get();

        List<Map<String, dynamic>> requests = [];
        for (var doc in snapshot.docs) {
          final request = doc.data();
          requests.add({...request, 'id': doc.id});
        }

        setState(() {
          _requests = requests;
        });
      }
    } catch (e) {
      print("Error fetching student history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch history. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRequest(String requestId, int index) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
      setState(() {
        _requests.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete request. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request History"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text("No request history found."))
              : SingleChildScrollView( // Wrap the main content with SingleChildScrollView
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true, // Make the ListView take only as much space as needed
                          physics: NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            final statusColor = request['status'] == 'Approved by HOD'
                                ? Colors.green
                                : request['status'] == 'Rejected'
                                    ? Colors.red
                                    : Colors.orange;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(request['leaveType'] ?? 'Unknown Leave Type'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status: ${request['status'] ?? 'Pending'}",
                                      style: TextStyle(color: statusColor),
                                    ),
                                    Text(
                                      "From: ${request['fromDate']?.split('T').first ?? 'N/A'} To: ${request['toDate']?.split('T').first ?? 'N/A'}",
                                    ),
                                    Text("Reason: ${request['reason'] ?? 'No Reason'}"),
                                    Text("Submitted On: ${request['submittedAt']?.toDate() ?? 'N/A'}"),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      request['status'] == 'Approved by HOD'
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: statusColor,
                                    ),
                                    SizedBox(height: 8.0),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
