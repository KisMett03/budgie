import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Dashboard', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            // Placeholder for dashboard analytics and graphs
            Text('Analytics and graphs will be displayed here.'),
          ],
        ),
      ),
    );
  }
}
