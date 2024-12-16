import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CTStudentList extends StatefulWidget {
  @override
  _CTStudentListState createState() => _CTStudentListState();
}

class _CTStudentListState extends State<CTStudentList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? classTeacherCourse;
  String? classTeacherSemester;
  String _sortBy = 'Name'; // Default sorting by Name

  @override
  void initState() {
    super.initState();
    _fetchClassTeacherDetails();
  }

  // Fetch Class Teacher details (course and semester)
  Future<void> _fetchClassTeacherDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final classTeacherData = await _firestore.collection('class_teachers').doc(user.email).get();
        if (classTeacherData.exists) {
          setState(() {
            classTeacherCourse = classTeacherData['course'];
            classTeacherSemester = classTeacherData['semester'];
          });
          print('Class Teacher Details: Course - $classTeacherCourse, Semester - $classTeacherSemester');
        } else {
          print('No data found for class teacher');
        }
      }
    } catch (e) {
      print('Error fetching class teacher details: $e');
    }
  }

  // Fetch the students who match the course and semester of the class teacher
  Future<List<Map<String, dynamic>>> _getStudents() async {
    if (classTeacherCourse == null || classTeacherSemester == null) {
      print('Course or semester is null.');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('students')
          .where('course', isEqualTo: classTeacherCourse)
          .where('semester', isEqualTo: classTeacherSemester)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No students found for the course: $classTeacherCourse and semester: $classTeacherSemester.');
      } else {
        print('Found ${snapshot.docs.length} students for course: $classTeacherCourse and semester: $classTeacherSemester.');
      }

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching student list: $e');
      return [];
    }
  }

  // Sorting function for student list
  void _sortList(List<Map<String, dynamic>> students) {
    if (_sortBy == 'Name') {
      students.sort((a, b) => (a['fullName'] ?? '').compareTo(b['fullName'] ?? ''));
    } else if (_sortBy == 'Email') {
      students.sort((a, b) => (a['email'] ?? '').compareTo(b['email'] ?? ''));
    }
  }

  // Show student details in a dialog
  void _showStudentDetailsDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(student['fullName'] ?? 'Student Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Name: ${student['fullName'] ?? 'N/A'}'),
                Text('Email: ${student['email'] ?? 'N/A'}'),
                Text('Course: ${student['course'] ?? 'N/A'}'),
                Text('Semester: ${student['semester'] ?? 'N/A'}'),
                Text('Phone: ${student['phone'] ?? 'N/A'}'),
                Text('College: ${student['college'] ?? 'N/A'}'),
                // Add more student details as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Name',
                child: Text('Sort by Name'),
              ),
              PopupMenuItem(
                value: 'Email',
                child: Text('Sort by Email'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('No students found.'));
          }

          final students = snapshot.data!;

          // Sort the student list based on selected sort option
          _sortList(students);

          return SingleChildScrollView( // Ensure the whole body is scrollable
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Optional padding for better layout
              child: Column(
                children: [
                  ListView.builder(
                    itemCount: students.length,
                    shrinkWrap: true, // Important to prevent ListView from taking all space
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling within ListView
                    itemBuilder: (context, index) {
                      final student = students[index];
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
                            student['fullName'] ?? 'No Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(student['email'] ?? 'No Email'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Show student details dialog on tap
                            _showStudentDetailsDialog(student);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
