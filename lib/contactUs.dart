import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsPage extends StatelessWidget {
  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Sahil Pokhrel',
      'role': 'Software Developer',
      'department': 'Information Science and Engineering',
      'email': 'sahilpokhrel010@gmail.com',
      'phone': '9380223684',
      'instagram': 'https://www.instagram.com/sketchwithweeb?igsh=MWF5c2Nicmd1aGtleg==',
      'linkedin': 'https://www.linkedin.com/in/sahil-pokhrel-a37163250/',
      'github': 'https://github.com/SahilPokhrel',
      'image': 'https://media.licdn.com/dms/image/v2/D4D03AQGBrtqPJNEszg/profile-displayphoto-shrink_800_800/B4DZPMHpnNHUAc-/0/1734296378818?e=1740009600&v=beta&t=KvWRpgUNPQGcV6z8VCwK-_AYpoMiDix25SKzu0kLNUU',
    },
    {
      'name': 'Shubhendu Singh',
      'role': 'Founder & CEO',
      'department': 'Information Science and Engineering',
      'email': 'shubhendu@example.com',
      'phone': '7892522835',
      'instagram': 'https://instagram.com/shubhendu',
      'linkedin': 'https://linkedin.com/shubhendu',
      'github': 'https://github.com/shubhendu',
      'image': 'https://media.licdn.com/dms/image/v2/D5603AQESZEVMRtXAMw/profile-displayphoto-shrink_400_400/B56ZPNgLBRG8Ag-/0/1734319594314?e=1740009600&v=beta&t=bLECqaWBWDwZq2MgPcVUxIvRkvwHtIxHYykwPvCw6B8',
    },
    {
      'name': 'Nitish Trigun',
      'role': 'Database Administrator',
      'department': 'Information Science and Engineering',
      'email': 'nitish@example.com',
      'phone': '6202620463',
      'instagram': 'https://instagram.com/nitish',
      'linkedin': 'https://linkedin.com/nitish',
      'github': 'https://github.com/nitish',
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRjZMe0x4ph0TAJD755xtnQsvfP5zpj6V6Q7Q&s',
    },
    {
      'name': 'Bishal Guha',
      'role': 'Product Manager',
      'department': 'Information Science and Engineering',
      'email': 'bishal@example.com',
      'phone': '8135026102',
      'instagram': 'https://instagram.com/bishal',
      'linkedin': 'https://linkedin.com/bishal',
      'github': 'https://github.com/bishal',
      'image': 'https://media.licdn.com/dms/image/v2/D5603AQFD8UeqIh8MuQ/profile-displayphoto-shrink_400_400/B56ZPBactRHoAo-/0/1734116757148?e=1740009600&v=beta&t=t0elVhvlFxfGjwj9BE__vI8GbRep6se6otQOAg0xnlM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 5,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.pinkAccent.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ...teamMembers.map((member) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 15,
                  shadowColor: Colors.deepPurple.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.deepPurple.shade50],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(member['image']!),
                        ),
                        SizedBox(height: 16),
                        Text(
                          member['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          member['role']!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.deepPurpleAccent.shade100,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          member['department']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurpleAccent.shade200,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconButton(FontAwesomeIcons.envelope, Colors.deepPurple, 'mailto:${member['email']}'),
                            _buildIconButton(FontAwesomeIcons.phone, Colors.deepPurple, 'tel:${member['phone']}'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildIconButton(FontAwesomeIcons.instagram, Colors.pink, member['instagram']!),
                            _buildIconButton(FontAwesomeIcons.linkedin, Colors.blue, member['linkedin']!),
                            _buildIconButton(FontAwesomeIcons.github, Colors.black, member['github']!),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 30),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, String url) {
    return IconButton(
      icon: Icon(icon),
      color: color,
      iconSize: 28,
      onPressed: () => _launchURL(url),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.envelope, color: Colors.white),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _launchURL('mailto:permitpro.lms@gmail.com'),
                child: Text(
                  'permitpro.lms@gmail.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            '© 2024 PermitPro: Leave Management System',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
