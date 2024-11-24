import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin.dart'; // Adjust the import path
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // For accessing the local file system
import 'hod_request.dart';
import 'hod_history.dart';

class HODDashboard extends StatefulWidget {
  @override
  _HODDashboardState createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Key to control the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Variables to hold the HOD data
  String? name;
  String? email;
  String? course;
  String? phone;
  String? college;
  String? profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchHODData();
  }

  Future<void> _fetchHODData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('hods').doc(user.email).get();

        if (userData.exists) {
          setState(() {
            name = userData['fullName'];
            email = userData['email'];
            course = userData['course'];
            phone = userData['phone'];
            college = userData['college'];
            profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      print("Error fetching HOD data: $e");
    }
  }

  // Function to store the image locally
  Future<void> _uploadImage() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);

      // Get the directory to store the image
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/${user.email}_profile.jpg';

      // Copy the picked file to the app's document directory
      await file.copy(newPath);

      // Update the local state with the new file path
      setState(() {
        profileImageUrl = newPath;  // Store the local path
      });

      // Update the Firestore document with the local image path (optional)
      await _firestore.collection('hods').doc(user.email).update({
        'profileImage': newPath,  // Storing the local file path in Firestore
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
      key: _scaffoldKey, // Attach the scaffold key here
      appBar: AppBar(
        title: Text('HOD Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Use the scaffold key
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(name ?? 'HOD Name'),
              accountEmail: Text(email ?? 'hod.email@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: profileImageUrl != null
                    ? FileImage(File(profileImageUrl!)) // Local file path
                    : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider,
              ),
            ),
            ListTile(
                          leading: Icon(Icons.history),
                          title: Text('History'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HodHistoryPage()), // Navigate to history
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
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
            // Profile photo and details section
            GestureDetector(
              onTap: _uploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null
                    ? FileImage(File(profileImageUrl!)) // Display local image
                    : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider,
              ),
            ),
            SizedBox(height: 12.0),
            Text(
              name ?? 'HOD Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Text(
              email ?? 'hod.email@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20.0),
            // HOD-specific buttons with simpler labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to List of Students in Semester
                    },
                    child: Text("Students"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to List of Class-Teachers
                    },
                    child: Text("Teachers"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            // Button for managing requests with a simple label
            ElevatedButton(
              onPressed: () {
                // Navigate to Manage Requests (approved by Class-Teachers)
                Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => HodRequestPage(),
                                                              ),
                                                            );
              },
              child: Text("Manage Requests"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                textStyle: TextStyle(fontSize: 14),
                minimumSize: Size(double.infinity, 50), // Make the button broader
              ),
            ),

            SizedBox(height: 30.0),
            // Additional Profile Information
            ListTile(
              leading: Icon(Icons.school),
              title: Text("Course"),
              subtitle: Text(course ?? "BE Computer Science & Engineering"),
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