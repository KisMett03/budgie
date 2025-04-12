import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your Expenses', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            // Placeholder for expense list
            Text('List of expenses will appear here.'),
          ],
        ),
      ),
    );
  }
}
