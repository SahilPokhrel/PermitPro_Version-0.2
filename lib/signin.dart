import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});
  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  signin() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image in the middle section
          Center(
            child: Image.network(
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_GA3B268_8jZwSarPR6Lb_QvsssLnrI5lzg&s',
              width: 150,
              height: 150,
            ),
          ),
          const SizedBox(height: 20), // Space between image and text

          // Welcome text
          const Text(
            'Welcome to PermitPro : LMS\n(Leave Management System)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(), // Space pushes content to the top

          Center(
            child: Image.network(
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQLAPkTRdWpmzO7p0N75Jus43i49W7LQ-IVrQ&s',
              width: 200,
              height: 450,
            ),
          ),
          const SizedBox(height: 20),

          // Continue with Google Button
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white, // Black text
                side: const BorderSide(color: Colors.black), // Black border
                minimumSize: const Size(300, 50), // Width and height of button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
              ),
              onPressed: (() => signin()),
              child: const Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
