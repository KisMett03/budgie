import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyFinancialApp());
}

class MyFinancialApp extends StatelessWidget {
  const MyFinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Financial Assistant',
      initialRoute: '/home',
      routes: appRoutes,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
