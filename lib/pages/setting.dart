import 'package:flutter/material.dart';
import 'package:todo_list/pages/condition_utilisation.dart';
import 'package:todo_list/pages/politique_confidentialit%C3%A9.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: [

          // 🔔 Notifications
          SwitchListTile(
            title: const Text("Notifications"),
            value: true,
            onChanged: (v) {},
          ),

          const Divider(),

          // 🌍 Langue
          ListTile(
            title: const Text("Langue"),
            subtitle: const Text("Français"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          // 🌙 Mode sombre
          ListTile(
            title: const Text("Theme"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(),

          // 📄 Conditions d’utilisation
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("Conditions d’utilisation"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsPage(),
                ),
              );
            },
          ),

          // 🔐 Politique de confidentialité
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Politique de confidentialité"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}