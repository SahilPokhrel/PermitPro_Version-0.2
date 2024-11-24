import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckStatus extends StatelessWidget {
  const CheckStatus({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Status'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchStudentRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No requests found.'),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final leaveType = request['leaveType'];
              final reason = request['reason'];
              final status = request['status'];
              final from = request['fromDate'];
              final to = request['toDate'];

              return Card(
                margin: const EdgeInsets.all(10.0),
                child: ListTile(
                  leading: Icon(
                    status == 'Pending'
                        ? Icons.hourglass_empty
                        : status.contains('Rejected')
                            ? Icons.cancel
                            : Icons.check_circle,
                    color: status == 'Pending'
                        ? Colors.orange
                        : status.contains('Rejected')
                            ? Colors.red
                            : Colors.green,
                  ),
                  title: Text('Leave Type: $leaveType'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: $reason'),
                      Text('From: $from'),
                      Text('To: $to'),
                      Text('Status: $status'),
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
