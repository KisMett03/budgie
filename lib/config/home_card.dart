import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const HomeCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
