import 'package:flutter/material.dart';

class QRPage extends StatelessWidget {
  final Map<String, dynamic> requestData;

  QRPage({required this.requestData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can display data from requestData here as needed
            Text("Request Data: ${requestData['leaveType']}"),
            // Placeholder for QR code (this will be implemented later)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // To navigate back
              },
              child: Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
