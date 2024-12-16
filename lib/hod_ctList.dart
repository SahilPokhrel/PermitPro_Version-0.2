import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HODCTList extends StatefulWidget {
  @override
  _HODCTListState createState() => _HODCTListState();
}

class _HODCTListState extends State<HODCTList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? hodCourse; // Store the course of the HOD
  List<Map<String, dynamic>> classTeachers = []; // List to store class-teacher details
  String? selectedSortOption = 'Name'; // Sorting option (initially by name)

  @override
  void initState() {
    super.initState();
    _fetchHODDetails();
  }

  // Fetch HOD details (course)
  Future<void> _fetchHODDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hodData = await _firestore.collection('hods').doc(user.email).get();
        if (hodData.exists) {
          setState(() {
            hodCourse = hodData['course'];
            // Fetch the class-teachers based on the HOD's course
            _fetchClassTeachers();
          });
        }
      }
    } catch (e) {
      print('Error fetching HOD details: $e');
    }
  }

  // Fetch class-teachers based on course
  Future<void> _fetchClassTeachers() async {
    if (hodCourse != null) {
      try {
        final snapshot = await _firestore
            .collection('class_teachers')
            .where('course', isEqualTo: hodCourse)
            .get();

        setState(() {
          classTeachers = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Sort the class-teachers list based on the selected sort option
          _sortClassTeachers();
        });
      } catch (e) {
        print('Error fetching class-teachers: $e');
      }
    }
  }

  // Sort class-teachers based on the selected option
  void _sortClassTeachers() {
    if (selectedSortOption == 'Sort by Name') {
      classTeachers.sort((a, b) => a['fullName'].compareTo(b['fullName']));
    } else if (selectedSortOption == 'Sort by Semester') {
      classTeachers.sort((a, b) => a['semester'].compareTo(b['semester']));
    }
    // Add more sorting options if needed, such as by email, etc.
  }

  // Show a dialog with class-teacher details when clicked
  void _showClassTeacherDetails(Map<String, dynamic> classTeacher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(classTeacher['fullName'] ?? 'No Name'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Email: ${classTeacher['email'] ?? 'No Email'}'),
                Text('Course: ${classTeacher['course'] ?? 'No Course'}'),
                Text('Semester: ${classTeacher['semester'] ?? 'No Semester'}'),
                Text('Phone: ${classTeacher['phone'] ?? 'No Phone'}'),
              ],
            ),
          ),
          actions: <Widget>[
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

  // Handle sorting option selection from the 3-dot menu
  void _onSortOptionSelected(String sortOption) {
    setState(() {
      selectedSortOption = sortOption;
      _sortClassTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class-Teacher List'),
        actions: [
          // 3-dot menu for sorting
          PopupMenuButton<String>(
            onSelected: _onSortOptionSelected,
            itemBuilder: (context) {
              return ['Sort by Name', 'Sort by Semester']
                  .map((option) => PopupMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ))
                  .toList();
            },
            icon: Icon(Icons.more_vert), // 3-dot icon
          ),
        ],
      ),
      body: hodCourse == null
          ? Center(child: CircularProgressIndicator()) // Show loading indicator until data is fetched
          : Column(
              children: [
                // List of class-teachers
                Expanded(
                  child: classTeachers.isNotEmpty
                      ? ListView.builder(
                          itemCount: classTeachers.length,
                          itemBuilder: (context, index) {
                            final ct = classTeachers[index];
                            return Card(
                              elevation: 4.0,
                              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(
                                    '${index + 1}', // Numerical bullet
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  ct['fullName'] ?? 'No Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(ct['semester'] ?? 'No Semester'),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  _showClassTeacherDetails(ct); // Show details on tap
                                },
                              ),
                            );
                          },
                        )
                      : Center(child: Text('No class-teachers found.')),
                ),
              ],
            ),
    );
  }
}
