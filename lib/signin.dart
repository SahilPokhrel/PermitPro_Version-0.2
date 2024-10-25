import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profilepage.dart';
import 'stu_dashboard.dart';
import 'admin_dashboard.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signin() async {
    try {
      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Sign-in aborted by user
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
          // Check if the user's profile exists in "students" or "admins" collections
          final DocumentSnapshot studentDoc =
              await _firestore.collection('students').doc(userEmail).get();
          final DocumentSnapshot adminDoc =
              await _firestore.collection('admins').doc(userEmail).get();

          // Redirect based on the existing profile or direct to ProfilePage for new users
          if (studentDoc.exists) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => StudentDashboard()));
          } else if (adminDoc.exists) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => AdminDashboard()));
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
              'Welcome!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Continue with Google to access your dashboard',
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
