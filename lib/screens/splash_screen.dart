import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.jpg',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome,
                size: 96,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'OleksandrAi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
