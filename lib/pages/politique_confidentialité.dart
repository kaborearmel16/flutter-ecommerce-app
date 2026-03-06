import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Politique de confidentialité")),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          """
Nous respectons votre vie privée.

Données collectées :
- Nom
- Numéro de téléphone
- Email (si fourni)

Utilisation :
- Authentification
- Sécurité
- Amélioration du service

Les données ne sont jamais vendues à des tiers.

Contact : kaborearmel16@gmail.com
""",
        ),
      ),
    );
  }
}