import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/pages/a_propos_site_web.dart';
import 'package:todo_list/pages/edit_profil.dart';
import 'package:todo_list/pages/favorite.dart';
import 'package:todo_list/pages/invite_ami.dart';
import 'package:todo_list/pages/setting.dart';
import 'package:todo_list/pages/suport_client.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profil"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(
                  name: data['name'] ?? "Utilisateur",
                  phone: data['phone'] ?? "70000000",
                  onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()),);}
                ),
                const SizedBox(height: 10),

                // SECTION MON COMPTE
                _SectionCard(
                  title: "Mon compte",
                  children: [
                    _ProfileItem(
                      icon: Icons.shopping_bag,
                      title: "Mes commandes",
                      onTap: () {
                        print("Mes commandes cliqué");
                      },
                    ),
                    _ProfileItem(
                      icon: Icons.favorite_border,
                      title: "Favoris",
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesPage()),);},
                    ),
                    _ProfileItem(
                      icon: Icons.account_balance_wallet,
                      title: "Paiements",
                      onTap: () {},
                    ),
                  ],
                ),

                // SECTION AVANTAGES
                _SectionCard(
                  title: "Avantages",
                  children: [
                    _ProfileItem(
                      icon: Icons.card_giftcard,
                      title: "Inviter un ami",
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendPage()),);},
                    ),
                    _ProfileItem(
                      icon: Icons.handshake,
                      title: "Nos partenaires",
                      onTap: () {},
                    ),
                    _ProfileItem(
                      icon: Icons.local_offer,
                      title: "Offres exclusives",
                      onTap: () {},
                    ),
                  ],
                ),

                // SECTION INFORMATIONS
                _SectionCard(
                  title: "Informations",
                  children: [
                    _ProfileItem(
                      icon: Icons.info_outline,
                      title: "A propos",
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()),);},
                    ),
                    _ProfileItem(
                      icon: Icons.support_agent,
                      title: "Support client",
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportPage()),);},
                    ),
                    _ProfileItem(
                      icon: Icons.settings,
                      title: "Paramètres",
                      onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()),);},
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _LogoutButton(),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// HEADER PROFIL
//////////////////////////////////////////////////////////////
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onTap; // obligatoire maintenant

  const _ProfileHeader({
    required this.name,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 10,), child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  phone,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

//////////////////////////////////////////////////////////////
/// SECTION CARD
//////////////////////////////////////////////////////////////
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// ITEM PROFIL
//////////////////////////////////////////////////////////////
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap; // obligatoire

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// LOGOUT
//////////////////////////////////////////////////////////////
class _LogoutButton extends StatelessWidget { 

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
      },
      icon: const Icon(Icons.logout, color: Colors.black),
      label: const Text(
        "Déconnexion",
        style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }
}