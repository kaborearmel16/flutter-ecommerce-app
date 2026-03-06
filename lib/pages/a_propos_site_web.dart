import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("À propos")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "MonApp v1.0\n\nApplication de vente moderne et sécurisée.",
        ),
      ),
    );
  }
}