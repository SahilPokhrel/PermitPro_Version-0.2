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

  @override
  void initState() {
    super.initState();
    _fetchStudentRequests();
  }

  Future<void> _fetchStudentRequests() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('requests')
            .where('student_email', isEqualTo: user.email)
            .get();

        List<Map<String, dynamic>> requests = [];
        for (var doc in snapshot.docs) {
          final request = doc.data();
          requests.add(request);
        }

        setState(() {
          _requests = requests;
        });
      }
    } catch (e) {
      print("Error fetching student requests: $e");
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
        child: _requests.isEmpty
            ? Center(child: Text("No request history found."))
            : ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(request['leave_type']),
                      subtitle: Text('Status: ${request['status']}'),
                      onTap: () {
                        // You can navigate to a detailed view of the request if needed
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
