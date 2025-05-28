import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final int personalBest;

  ProfileScreen({required this.personalBest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Profile", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🏆 Personal Best: $personalBest/100", style: TextStyle(color: Colors.orangeAccent, fontSize: 20)),
            SizedBox(height: 20),
            Text("App version: 1.0.0", style: TextStyle(color: Colors.grey)),
            // Add more user settings here
          ],
        ),
      ),
    );
  }
}
