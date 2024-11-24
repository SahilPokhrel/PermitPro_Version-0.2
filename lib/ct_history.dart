import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CTHistoryPage extends StatefulWidget {
  @override
  _CTHistoryPageState createState() => _CTHistoryPageState();
}

class _CTHistoryPageState extends State<CTHistoryPage> {
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
        }
      }
    } catch (e) {
      print("Error fetching class teacher details: $e");
    }
  }

  // Fetch requests history for the class teacher's course and semester
  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('course', isEqualTo: course)
          .where('semester', isEqualTo: semester)
          .where('status', isNotEqualTo: 'pending')  // Exclude pending requests
          .get();

      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    } catch (e) {
      print("Error fetching request history: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No request history available"));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(request['leave_type']),
                  subtitle: Text("Reason: ${request['reason']}"),
                  trailing: Icon(
                    request['status'] == 'approved_by_class_teacher' && request['approved_by_hod'] == false
                        ? Icons.hourglass_empty
                        : Icons.check_circle,
                    color: request['status'] == 'approved_by_class_teacher' && request['approved_by_hod'] == false
                        ? Colors.orange
                        : Colors.green,
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
