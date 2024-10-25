import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signin.dart';
import 'stu_dashboard.dart';
import 'admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkUserStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final userRole = snapshot.data;
          if (userRole == 'Student') {
            return StudentDashboard();
          } else if (userRole == 'Admin') {
            return AdminDashboard();
          } else {
            return const Signin();
          }
        } else {
          return const Signin(); // Fallback in case of an error
        }
      },
    );
  }

  Future<String?> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userEmail = user.email;

      // Check if the user's profile exists in Firestore
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(userEmail)
          .get();
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userEmail)
          .get();

      if (studentDoc.exists) {
        return 'Student';
      } else if (adminDoc.exists) {
        return 'Admin';
      }
    }
    return null; // User is not logged in or does not have a profile
  }
}
