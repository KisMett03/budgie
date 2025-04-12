import 'package:flutter/material.dart';

class CustomSignInButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;

  const CustomSignInButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100), // pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gotham',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
