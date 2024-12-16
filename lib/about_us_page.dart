import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Description Section
              Text(
                'Welcome to PermitPro: Leave Management System (LMS)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'PermitPro is a modern, user-friendly leave management system that helps students, '
                'HODs (Heads of Department), and Class Teachers easily manage and track leave requests. '
                'With role-based access and streamlined processes, PermitPro ensures smooth communication and operations.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 24),

              // Features Section
              Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 8),
              _buildFeatureTile('Role-based access (Student, HOD, Class Teacher)'),
              _buildFeatureTile('Google Sign-In integration'),
              _buildFeatureTile('Profile creation and management'),
              _buildFeatureTile('Leave request management with multiple leave types'),
              _buildFeatureTile('Admin dashboard for managing requests and users'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String feature) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 20),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            feature,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
