import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Support client")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text("WhatsApp"),
            subtitle: const Text("+226 52 94 84 64"),
            onTap: () async {
              final uri = Uri.parse("https://wa.me/22652948464");
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Email"),
            subtitle: const Text("support@monapp.com"),
            onTap: () async {
              final uri = Uri.parse("mailto:kaborearmel16gmail.com");
              await launchUrl(uri);
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text("Appeler"),
            onTap: () async {
              final uri = Uri.parse("tel:+22665714472");
              await launchUrl(uri);
            },
          ),
        ],
      ),
    );
  }
}