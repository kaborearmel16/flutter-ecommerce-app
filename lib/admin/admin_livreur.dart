import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CouriersPage extends StatefulWidget {
  const CouriersPage({super.key});

  @override
  State<CouriersPage> createState() => _CouriersPageState();
}

class _CouriersPageState extends State<CouriersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Livreurs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Users")
            .where("role", isEqualTo: "delivery")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final couriers = snapshot.data!.docs;
          if (couriers.isEmpty) return const Center(child: Text("Aucun livreur trouvé"));

          return ListView.builder(
            itemCount: couriers.length,
            itemBuilder: (context, index) {
              final doc = couriers[index];
              final data = doc.data() as Map<String, dynamic>;
              final isBlocked = data['isBlocked'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((data['email'] ?? "L")[0].toUpperCase()),
                  ),
                  title: Text(data['email'] ?? "Sans email",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Solde : ${data['balance'] ?? 0} FCFA", style: const TextStyle(fontSize: 12)),
                      Text("Statut : ${isBlocked ? 'Bloqué' : 'Actif'}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourierDetailPage(uid: doc.id),
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

// ================= DÉTAIL LIVREUR =================
class CourierDetailPage extends StatelessWidget {
  final String uid;

  const CourierDetailPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Détails livreur")),
      body: FutureBuilder<DocumentSnapshot>(
        future: db.collection("Users").doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text("Livreur introuvable"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isBlocked = data['isBlocked'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= INFORMATIONS =================
                _infoCard(
                  title: "Informations",
                  icon: Icons.local_shipping,
                  color: Colors.green,
                  children: [
                    Text("Email: ${data['email'] ?? 'Non renseigné'}"),
                    Text("Solde: ${data['balance'] ?? 0} FCFA"),
                    Text("Statut: ${isBlocked ? 'Bloqué' : 'Actif'}"),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= ACTIONS =================
                _actionCard(context, uid, data),

                const SizedBox(height: 12),

                // ================= LIVRAISONS =================
                StreamBuilder<QuerySnapshot>(
                  stream: db.collection("deliveryRequests").where("assignedTo", isEqualTo: uid).snapshots(),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          ...children,
        ]),
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
                  }
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text("Ajuster solde"),
              ),
              // Supprimer
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirmer la suppression"),
                      content: const Text("Voulez-vous vraiment supprimer ce livreur ?"),
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