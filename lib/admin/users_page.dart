import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String filter = "all";

  bool _applyFilter(Map<String, dynamic> data) {
    final role = data['role'] ?? 'user';
    final isBlocked = data['isBlocked'] ?? false;
    final balance = (data['balance'] ?? 0).toDouble();

    switch (filter) {
      case 'active':
        return !isBlocked;
      case 'blocked':
        return isBlocked;
      case 'admin':
        return role == 'admin';
      case 'delivery':
        return role == 'delivery';
      case 'user':
        return role == 'user';
      case 'balance_pos':
        return balance > 0;
      case 'balance_zero':
        return balance == 0;
      default:
        return true; // all
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Utilisateurs"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text("Tous")),
              PopupMenuItem(value: 'active', child: Text("Actifs")),
              PopupMenuItem(value: 'blocked', child: Text("Bloqués")),
              PopupMenuItem(value: 'admin', child: Text("Admins")),
              PopupMenuItem(value: 'delivery', child: Text("Livreurs")),
              PopupMenuItem(value: 'user', child: Text("Utilisateurs")),
              PopupMenuItem(value: 'balance_pos', child: Text("Solde > 0")),
              PopupMenuItem(value: 'balance_zero', child: Text("Solde = 0")),
            ],
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snapshot.data!.docs;

          final filteredUsers = allUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _applyFilter(data);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text("Aucun utilisateur trouvé"));
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final doc = filteredUsers[index];
              final data = doc.data() as Map<String, dynamic>;

              final role = data['role'] ?? 'user';
              final isBlocked = data['isBlocked'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (data['email'] ?? "U")[0].toUpperCase(),
                    ),
                  ),
                  title: Text(
                    data['email'] ?? "Sans email",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rôle : $role", style: const TextStyle(fontSize: 12)),
                      Text("Solde : ${data['balance'] ?? 0} FCFA", style: const TextStyle(fontSize: 12)),
                      Text("Statut : ${isBlocked ? 'Bloqué' : 'Actif'}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailPage(uid: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final String uid;

  const UserDetailPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Détails utilisateur")),
      body: FutureBuilder<DocumentSnapshot>(
        future: db.collection("Users").doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Utilisateur introuvable"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'user';
          final isBlocked = data['isBlocked'] ?? false;
          final isAdmin = role == 'admin';
          final isDelivery = role == 'delivery';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= INFORMATIONS =================
                _infoCard(
                  title: "Informations",
                  icon: Icons.person,
                  color: Colors.blue,
                  children: [
                    Text("Email: ${data['email'] ?? 'Non renseigné'}"),
                    Text("Rôle: $role"),
                    Text("Solde: ${data['balance'] ?? 0} FCFA"),
                    Text("Email vérifié: ${(data['emailVerified'] ?? false) ? 'Oui' : 'Non'}"),
                    Text("Statut: ${isBlocked ? 'Bloqué' : 'Actif'}"),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= ACTIONS =================
                _actionCard(context, uid, data),

                const SizedBox(height: 12),

                // ================= TRANSACTIONS (uniquement user) =================
                if (!isAdmin && !isDelivery)
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection("transactions").where("uid", isEqualTo: uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final transactions = snapshot.data!.docs;
                      int success = 0, failed = 0, pending = 0;
                      for (var t in transactions) {
                        final tData = t.data() as Map<String, dynamic>;
                        final status = tData['status'] ?? 'pending';
                        if (status == 'success') success++;
                        if (status == 'failed') failed++;
                        if (status == 'pending') pending++;
                      }
                      return _statCard(
                        title: "Transactions",
                        icon: Icons.swap_horiz,
                        color: Colors.teal,
                        stats: {
                          "Total": transactions.length.toString(),
                          "Réussies": success.toString(),
                          "Échouées": failed.toString(),
                          "En attente": pending.toString(),
                        },
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // ================= ACHATS (uniquement user) =================
                if (!isAdmin && !isDelivery)
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection("purchases").where("uid", isEqualTo: uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final purchases = snapshot.data!.docs;
                      int delivered = 0, pending = 0, canceled = 0;
                      for (var p in purchases) {
                        final pData = p.data() as Map<String, dynamic>;
                        final status = pData['status'] ?? 'pending';
                        if (status == 'delivered') delivered++;
                        if (status == 'pending') pending++;
                        if (status == 'canceled') canceled++;
                      }
                      return _statCard(
                        title: "Achats",
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                        stats: {
                          "Total": purchases.length.toString(),
                          "Livrés": delivered.toString(),
                          "En attente": pending.toString(),
                          "Annulés": canceled.toString(),
                        },
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // ================= LIVRAISONS (uniquement delivery) =================
                if (isDelivery)
                  StreamBuilder<QuerySnapshot>(
                    stream: db.collection("deliveryRequests").where("uid", isEqualTo: uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final deliveries = snapshot.data!.docs;
                      int assigned = 0, delivered = 0;
                      for (var d in deliveries) {
                        final dData = d.data() as Map<String, dynamic>;
                        final status = dData['status'] ?? 'assigned';
                        if (status == 'assigned') assigned++;
                        if (status == 'delivered') delivered++;
                      }
                      return _statCard(
                        title: "Livraisons",
                        icon: Icons.local_shipping,
                        color: Colors.green,
                        stats: {
                          "Total": deliveries.length.toString(),
                          "Assignées": assigned.toString(),
                          "Livrées": delivered.toString(),
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= WIDGET INFO =================
  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  // ================= WIDGET STAT =================
  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, String> stats,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 12),
          ...stats.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(e.key), Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold))],
                ),
              )),
        ]),
      ),
    );
  }

  // ================= WIDGET ACTIONS =================
  Widget _actionCard(BuildContext context, String uid, Map<String, dynamic> data) {
    final isBlocked = data['isBlocked'] ?? false;
    final isAdmin = data['role'] == 'admin';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Bloquer / Débloquer
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("Users").doc(uid).update({'isBlocked': !isBlocked});
                },
                icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
                label: Text(isBlocked ? "Débloquer" : "Bloquer"),
              ),
              // Réinitialiser mot de passe
              ElevatedButton.icon(
                onPressed: () async {
                  final email = data['email'];
                  if (email != null) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email de réinitialisation envoyé !")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur: $e")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.password),
                label: const Text("Réinitialiser mot de passe"),
              ),
              // Notifier
              ElevatedButton.icon(
                onPressed: () async {
                  final messageController = TextEditingController();
                  final message = await showDialog<String>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Envoyer notification"),
                      content: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(labelText: "Message"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                        TextButton(onPressed: () => Navigator.pop(context, messageController.text), child: const Text("Envoyer")),
                      ],
                    ),
                  );
                  if (message != null && message.isNotEmpty) {
                    await FirebaseFirestore.instance.collection("notifications").add({
                      'uid': uid,
                      'message': message,
                      'createdAt': FieldValue.serverTimestamp(),
                      'seen': false,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification envoyée !")),
                    );
                  }
                },
                icon: const Icon(Icons.notifications),
                label: const Text("Notifier"),
              ),
              // Ajuster solde
              ElevatedButton.icon(
                onPressed: () async {
                  final amountController = TextEditingController();
                  final result = await showDialog<int>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Ajuster solde"),
                      content: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Montant (+/-)"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                        TextButton(
                            onPressed: () {
                              final val = int.tryParse(amountController.text);
                              Navigator.pop(context, val);
                            },
                            child: const Text("Valider")),
                      ],
                    ),
                  );

                  if (result != null) {
                    final userRef = FirebaseFirestore.instance.collection("Users").doc(uid);
                    final userSnap = await userRef.get();
                    final oldBalance = userSnap['balance'] ?? 0;
                    final newBalance = oldBalance + result;

                    await userRef.update({'balance': newBalance});
                    await FirebaseFirestore.instance.collection("transactions").add({
                      'uid': uid,
                      'amount': result,
                      'type': 'adjustment',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Solde mis à jour: $newBalance FCFA")),
                    );
                  }
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text("Ajuster solde"),
              ),
              // Admin
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("Users").doc(uid).update({'role': isAdmin ? 'user' : 'admin'});
                },
                icon: Icon(isAdmin ? Icons.person : Icons.admin_panel_settings),
                label: Text(isAdmin ? "Retirer admin" : "Rendre admin"),
              ),
              // Supprimer
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirmer la suppression"),
                      content: const Text("Voulez-vous vraiment supprimer cet utilisateur ?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection("Users").doc(uid).delete();
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text("Supprimer"),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}