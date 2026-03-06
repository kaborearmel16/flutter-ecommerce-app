import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le profil"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(
              decoration: InputDecoration(labelText: "Nom"),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: "Téléphone"),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: "Email"),
            ),
          ],
        ),
      ),
    );
  }
}