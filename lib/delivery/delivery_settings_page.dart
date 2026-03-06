import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/delivery/delivery_stats_page.dart';

class DeliverySettingsPage extends StatelessWidget {
  const DeliverySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('Users').doc(uid);

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Paramètres"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[50],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          // ===== PROFIL =====
          _sectionTitle("Compte"),
          _card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text("Profil"),
              subtitle: const Text("Informations personnelles"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Page profil plus tard
              },
            ),
          ),

          // ===== STATISTIQUES =====
          _sectionTitle("Recommandé"),
          _card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.blue),
              title: const Text("Statistiques"),
              subtitle: const Text("Livraisons, revenus, performance"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeliveryStatsPage(),
                  )
                );
              },
            ),
          ),

          // ===== APPARENCE =====
          _sectionTitle("Apparence"),
          _card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.color_lens),
                  title: Text("Thème"),
                  subtitle: Text("Choisir l’apparence"),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _themeButton(
                        icon: Icons.light_mode,
                        label: "Clair",
                        color: Colors.orange,
                        onTap: () async {
                          await userRef.update({'theme': 'light'});
                          _snack(context, "Thème clair activé");
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _themeButton(
                        icon: Icons.dark_mode,
                        label: "Sombre",
                        color: Colors.blueGrey,
                        onTap: () async {
                          await userRef.update({'theme': 'dark'});
                          _snack(context, "Thème sombre activé");
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== NOTIFICATIONS =====
          _sectionTitle("Notifications"),
          _card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              subtitle: const Text("Nouvelles livraisons, mises à jour"),
              value: true, // à lier plus tard
              onChanged: (val) async {
                await userRef.update({'notifications': val});
              },
            ),
          ),

          // ===== LANGUE =====
          _sectionTitle("Langue"),
          _card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Langue"),
              subtitle: const Text("Français"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await userRef.update({'language': 'fr'});
                _snack(context, "Langue définie sur Français");
              },
            ),
          ),

          // ===== SÉCURITÉ =====
          _sectionTitle("Sécurité"),
          _card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Changer mot de passe"),
                  onTap: () {
                    // Firebase reset password
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text("Confidentialité"),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ===== DÉCONNEXION =====
          _sectionTitle("Session"),
          _card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Déconnexion",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS UI =================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _themeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}