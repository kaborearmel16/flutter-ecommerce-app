import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conditions d’utilisation")),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          """
En utilisant cette application, vous acceptez les conditions suivantes :

1. L’utilisateur est responsable de son compte.
2. Les informations fournies doivent être exactes.
3. Toute utilisation abusive peut entraîner la suspension du compte.
4. L’application peut être modifiée à tout moment.

Dernière mise à jour : 2026
""",
        ),
      ),
    );
  }
}