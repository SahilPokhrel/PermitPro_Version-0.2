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
import 'hod_studentList.dart'; // Ensure the correct path to your hod_studentList.dart file
import 'hod_ctList.dart';
import 'about_us_page.dart';
import 'contactUs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback.dart';

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
  SharedPreferences? prefs;


  @override
  void initState() {
    super.initState();
    _initialize();
    _fetchHODData();
  }

  Future<void> _initialize() async {
      // Initialize SharedPreferences
      prefs = await SharedPreferences.getInstance();

      // Fetch student data
      await _fetchHODData();

      // Check and load profile photo
      await _checkProfilePhoto();

      // Check if the profile photo has been uploaded previously
      bool? isProfilePhotoUploaded = prefs?.getBool('isProfilePhotoUploaded') ?? false;
      if (!isProfilePhotoUploaded) {
        _showProfileImageMissingDialog(); // Show dialog if no profile image is uploaded
      }
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
    Future<void> _checkProfilePhoto() async {
      try {
        final User? user = _auth.currentUser;
        if (user != null) {
          // Retrieve the image path from SharedPreferences
          String? savedPath = prefs?.getString('profileImagePath');
    
          if (savedPath != null && File(savedPath).existsSync()) {
            setState(() {
              profileImageUrl = savedPath;
            });
          } else {
            // Set flag to indicate that the photo hasn't been uploaded
            prefs?.setBool('isProfilePhotoUploaded', false);
          }
        }
      } catch (e) {
        print("Error checking profile photo: $e");
      }
    }
    
    
    
      void _showProfileImageMissingDialog() {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Profile Photo Missing'),
              content: Text('Please upload a profile photo to proceed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _uploadImage();
                  },
                  child: Text('Upload Now'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    
      Future<void> _uploadImage() async {
        try {
          final User? user = _auth.currentUser;
          if (user == null) return;
    
          // Show a bottom sheet with the 3 options: View Image, Change Image, Delete Image
          await showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Option to view current profile image if available
                    if (profileImageUrl != null)
                      ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Image'),
                        onTap: () {
                          // Close the bottom sheet
                          Navigator.of(context).pop();
    
                          // Show the profile image in a new dialog or view
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Profile Image'),
                                content: Image.file(File(profileImageUrl!)),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Close'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    // Option to change profile image
                    ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Change Image'),
                      onTap: () async {
                        // Close the bottom sheet
                        Navigator.of(context).pop();
    
                        // Allow the user to choose a new image
                        final ImageSource? source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.photo_library),
                                    title: Text('Choose from Gallery'),
                                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.camera_alt),
                                    title: Text('Take a Photo'),
                                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
    
                        if (source == null) return; // User cancelled
    
                        // Pick an image from the selected source
                        final XFile? pickedFile = await _picker.pickImage(source: source);
    
                        if (pickedFile == null) return;
    
                        final File file = File(pickedFile.path);
    
                        // Show a confirmation dialog before updating
                        bool? shouldUpdate = await _showConfirmationDialog();
    
                        if (shouldUpdate == true) {
                          // Get the directory to store the image
                          final directory = await getApplicationDocumentsDirectory();
                          final String newPath = '${directory.path}/${user.email}_profile.jpg';
    
                          // Copy the picked file to the app's document directory
                          await file.copy(newPath);
    
                          setState(() {
                            profileImageUrl = newPath; // Store the local path
                          });
    
                          // Update Firestore with the new image path
                          await _firestore.collection('students').doc(user.email).update({
                            'profileImage': newPath,
                          });
    
                          // Set flag to indicate that the profile photo is uploaded
                          prefs?.setBool('isProfilePhotoUploaded', true);
    
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile image updated!")),
                          );
    
                          // Force a full page refresh
                          await _fetchHODData();
                          _initState();  // Force re-fetch or reset states like initialization
                        } else {
                          // If user cancels, do nothing
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile image update aborted.")),
                          );
                        }
                      },
                    ),
                    // Option to delete profile image
                    if (profileImageUrl != null)
                      ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete Image'),
                        onTap: () async {
                          // Close the bottom sheet
                          Navigator.of(context).pop();
    
                          final directory = await getApplicationDocumentsDirectory();
                          final File file = File('${directory.path}/${user.email}_profile.jpg');
    
                          if (await file.exists()) {
                            await file.delete(); // Delete the local file
                          }
    
                          // Remove the profile image URL from Firestore
                          await _firestore.collection('students').doc(user.email).update({
                            'profileImage': null,
                          });
    
                          setState(() {
                            profileImageUrl = null; // Update the UI
                          });
    
                          // Set flag to indicate the image has been deleted
                          prefs?.setBool('isProfilePhotoUploaded', false);
    
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile image deleted!")),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        } catch (e) {
          print("Error handling image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error handling image: $e")),
          );
        }
      }
    
    
      // Confirmation dialog for image update
      Future<bool?> _showConfirmationDialog() {
        return showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Update"),
              content: Text("Do you really want to update the profile picture?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Confirm update
                  },
                  child: Text('Confirm'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Cancel update
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      }
    
      // Method to refresh the page like a restart
      Future<void> _initState() async {
        // Re-fetch the data, reinitialize variables, and rebuild the page if necessary
        await _fetchHODData();
        setState(() {});
      }
    
    
    
    
    
        // Function to delete the profile image
        Future<void> _deleteProfileImage() async {
          try {
            final User? user = _auth.currentUser;
            if (user == null) return;
    
            // Fetch the directory for local storage
            final directory = await getApplicationDocumentsDirectory();
            final File file = File('${directory.path}/${user.email}_profile.jpg'); // Construct the file path
    
            // Check if the file exists and delete it
            if (await file.exists()) {
              await file.delete(); // Delete the local profile image
            }
    
            // Remove the profile image URL from Firestore
            await _firestore.collection('students').doc(user.email).update({
              'profileImageUrl': FieldValue.delete(), // Remove the profileImageUrl field
            });
    
            setState(() {
              profileImageUrl = null; // Update the UI to reflect the change
            });
    
            // Show confirmation snack bar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile image deleted!")),
            );
          } catch (e) {
            print("Error deleting profile image: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to delete image: $e")),
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
                    : const AssetImage('assets/profile_placeholder.jpg')
                        as ImageProvider,
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HodHistoryPage()), // Navigate to history
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback'),
              onTap: () {
                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackPage(
                                      name: name ?? 'Student Name',
                                      email: email ?? 'student.email@example.com',
                                    ),
                                  ),
                                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About Us'),
              onTap: () {
                Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => AboutUsPage(),
                                                        ),
                                                      );
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail),
              title: Text('Contact Us'),
              onTap: () {
                Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) => ContactUsPage(),
                                                                        ),
                                                                      );
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
            GestureDetector(
              onTap: () async {
                await _uploadImage();
              },
              onLongPress: () async {
                await _deleteProfileImage();
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null
                    ? FileImage(File(profileImageUrl!)) // Display the local image file
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to List of Students in Semester
                      Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => HODStudentList(),
                                                              ),
                                                            );
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
                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HODCTList(),
                                        ),
                                      );
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
            ElevatedButton(
              onPressed: () {
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
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 30.0),
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
