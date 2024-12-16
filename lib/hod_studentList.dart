import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hod_studentList.dart'; // Ensure the correct path to your hod_studentList.dart file


class HODStudentList extends StatefulWidget {
  @override
  _HODStudentListState createState() => _HODStudentListState();
}

class _HODStudentListState extends State<HODStudentList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? hodCourse;
  String? selectedSemester;
  List<String> semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'];
  String _sortBy = 'Name'; // Default sorting by Name

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
          });
        }
      }
    } catch (e) {
      print('Error fetching HOD details: $e');
    }
  }

  // Fetch the students who match the course and semester of the HOD
  Future<List<Map<String, dynamic>>> _getStudents() async {
    try {
      if (hodCourse != null && selectedSemester != null) {
        final snapshot = await _firestore
            .collection('students')
            .where('course', isEqualTo: hodCourse)
            .where('semester', isEqualTo: selectedSemester)
            .get();

        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } else {
        return []; // No students found if course or semester is not selected
      }
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
      body: Column(
        children: [
          // Dropdown for selecting semester
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSemester,
              hint: Text('Select Semester'),
              onChanged: (newValue) {
                setState(() {
                  selectedSemester = newValue;
                });
              },
              items: semesters.map<DropdownMenuItem<String>>((semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
            ),
          ),
          // FutureBuilder to fetch and display the students
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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

                return ListView.builder(
                  itemCount: students.length,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
