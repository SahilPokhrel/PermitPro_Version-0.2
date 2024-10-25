import 'package:flutter/material.dart';
import 'signin.dart'; // Adjust the import path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class StudentDashboard extends StatelessWidget {
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
        title: Text('Student Dashboard'),
      ),
      body: Center(
        child: Text('Welcome to the Student Dashboard!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _signOut(context),
        child: Icon(Icons.logout),
      ),
    );
  }
}
