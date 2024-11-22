import 'package:flutter/material.dart';
import 'signin.dart'; // Adjust the import path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ClassTeacherDashboard extends StatelessWidget {
  // Function to handle sign-out
  void _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Signin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class Teacher Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the Class Teacher Dashboard!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Add features specific to Class Teacher
            ElevatedButton(
              onPressed: () {
                // Placeholder for class request management logic
              },
              child: Text('Manage Leave Requests'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Placeholder for attendance report viewing logic
              },
              child: Text('View Attendance Reports'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _signOut(context),
        tooltip: 'Logout',
        child: Icon(Icons.logout),
      ),
    );
  }
}
