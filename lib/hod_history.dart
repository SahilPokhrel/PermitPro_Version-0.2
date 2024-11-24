import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting the date/time

class HodHistoryPage extends StatefulWidget {
  @override
  _HodHistoryPageState createState() => _HodHistoryPageState();
}

class _HodHistoryPageState extends State<HodHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _firestore.collection('requests')
        .where('approved_by_hod', isEqualTo: true) // Show only requests approved by HOD
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HOD Request History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading history"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No request history"));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
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
                  subtitle: Text("$leaveType - From: ${DateFormat.yMMMd().format(fromDateTime)} To: ${DateFormat.yMMMd().format(toDateTime)}\nReason: $reason\nStatus: $status"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
