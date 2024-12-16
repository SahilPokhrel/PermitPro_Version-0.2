import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profilepage.dart';
import 'stu_dashboard.dart';
import 'hod_dashboard.dart';
import 'ct_dashboard.dart'; // Import Class-Teacher Dashboard

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle Google Sign-In
  Future<void> signin() async {
    try {
      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Sign-in aborted by the user
        return;
      }

      // Retrieve Google sign-in authentication
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential for Firebase Authentication
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final String? userEmail = user.email;

        if (userEmail != null) {
          // Check if the user's profile exists in Firestore collections
          final DocumentSnapshot studentDoc =
              await _firestore.collection('students').doc(userEmail).get();
          final DocumentSnapshot hodDoc =
              await _firestore.collection('hods').doc(userEmail).get(); // Updated
          final DocumentSnapshot classTeacherDoc =
              await _firestore.collection('class_teachers').doc(userEmail).get();

          // Redirect based on the existing profile or navigate to ProfilePage
          if (studentDoc.exists) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => StudentDashboard()));
          } else if (hodDoc.exists) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => HODDashboard()));
          } else if (classTeacherDoc.exists) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => ClassTeacherDashboard()));
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(email: userEmail)));
          }
        }
      }
    } catch (e) {
      print("Error in Google Sign-In: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-in failed. Please try again.")),
      );
    }
  }

  // Function to check user's current authentication state on app reopen
  Future<void> checkAuthState() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final String? userEmail = user.email;

      if (userEmail != null) {
        // Check if the user's profile exists in Firestore collections
        final DocumentSnapshot studentDoc =
            await _firestore.collection('students').doc(userEmail).get();
        final DocumentSnapshot hodDoc =
            await _firestore.collection('hods').doc(userEmail).get(); // Updated
        final DocumentSnapshot classTeacherDoc =
            await _firestore.collection('class_teachers').doc(userEmail).get();

        // Redirect based on the existing profile
        if (studentDoc.exists) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => StudentDashboard()));
        } else if (hodDoc.exists) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => HODDashboard()));
        } else if (classTeacherDoc.exists) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ClassTeacherDashboard()));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfilePage(email: userEmail)));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Check authentication state on app launch
    checkAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/logo.png',
                height: 100), // Add your image asset
            SizedBox(height: 20),
            Text(
              'Leave Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Streamlining Leave Management for Students and Educators',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: signin,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('lib/assets/images.png',
                      height: 24), // Add Google icon asset
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
