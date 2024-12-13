import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin.dart'; // Adjust the import path
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // For accessing the local file system
import 'generate_request.dart';
import 'check_status.dart';
import 'history_page.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? name;
  String? email;
  String? course;
  String? usn;
  String? phone;
  String? college;
  String? profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('students').doc(user.email).get();

        if (userData.exists) {
          setState(() {
            name = userData['fullName'];
            email = userData['email'];
            course = userData['course'];
            usn = userData['usn'];
            phone = userData['phone'];
            college = userData['college'];
            profileImageUrl = userData['profileImage'];
          });

          // Show a message to upload the profile image if it's missing
          if (profileImageUrl == null || profileImageUrl!.isEmpty) {
            _showImageUploadDialog();
          }
        }
      }
    } catch (e) {
      print("Error fetching student data: $e");
    }
  }

  // Show a dialog to upload the profile image
  void _showImageUploadDialog() {
    // Make sure to call this inside setState() or when the widget is mounted
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Profile Image Missing'),
            content: Text('Please upload a profile image to complete your profile.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _uploadImage();
                },
                child: Text('Upload Image'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Later'),
              ),
            ],
          );
        },
      );
    }
  }

  // Function to upload image
  Future<void> _uploadImage() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/${user.email}_profile.jpg';
      await file.copy(newPath);

      setState(() {
        profileImageUrl = newPath;  // Store the local path
      });

      await _firestore.collection('students').doc(user.email).update({
        'profileImage': newPath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile image updated!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  // Sign out function
  void _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Signin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Student Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(name ?? 'Student Name'),
              accountEmail: Text(email ?? 'student.email@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: profileImageUrl != null
                    ? FileImage(File(profileImageUrl!))
                    : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider,
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About Us'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail),
              title: Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () => _signOut(context),
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Developed by SBNS with ❤️",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.0),
            GestureDetector(
              onTap: _uploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null
                    ? FileImage(File(profileImageUrl!))
                    : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider,
              ),
            ),
            SizedBox(height: 12.0),
            SizedBox(height: 12.0),
            Text(
              name ?? 'Student Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Text(
              email ?? 'student.email@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenerateRequest(),
                        ),
                      );
                    },
                    child: Text("Add Request"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CheckStatus()),
                      );
                    },
                    child: const Text("Check Status"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.0),
            ListTile(
              leading: Icon(Icons.school),
              title: Text("Course"),
              subtitle: Text(course ?? "BE Computer Science & Engineering"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("USN"),
              subtitle: Text(usn ?? "1TJ18CS001"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text("Phone"),
              subtitle: Text(phone ?? "123-456-7890"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text("College"),
              subtitle: Text(college ?? "T John Group of Institutions"),
            ),
          ],
        ),
      ),
    );
  }
}

