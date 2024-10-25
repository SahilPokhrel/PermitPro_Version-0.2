import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure you import Firestore
import 'package:permit_pro/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firestore settings here if necessary (this is optional)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    // Note: The following host setting is not necessary unless you are using a custom Firestore emulator or backend.
    // host: 'your_host',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permit Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Wrapper(),
    );
  }
}
