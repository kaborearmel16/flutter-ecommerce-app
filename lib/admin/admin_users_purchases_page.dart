import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/admin/invoice_page.dart';

class AdminUsersPurchasesPage extends StatefulWidget {
  const AdminUsersPurchasesPage({super.key});

  @override
  State<AdminUsersPurchasesPage> createState() =>
      _AdminUsersPurchasesPageState();
}

class _AdminUsersPurchasesPageState extends State<AdminUsersPurchasesPage> {
  final db = FirebaseFirestore.instance;
  String statusFilter = 'all'; // all, pending, delivered, canceled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Achats par utilisateur"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== FILTRES =====
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text("Tous"),
                  selected: statusFilter == 'all',
                  onSelected: (_) => setState(() => statusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Livrés"),
                  selected: statusFilter == 'delivered',
                  onSelected: (_) => setState(() => statusFilter = 'delivered'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("En attente"),
                  selected: statusFilter == 'pending',
                  onSelected: (_) => setState(() => statusFilter = 'pending'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Annulés"),
                  selected: statusFilter == 'canceled',
                  onSelected: (_) => setState(() => statusFilter = 'canceled'),
                ),
              ],
            ),
          ),

          // ===== LISTE DES ACHATS =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('purchases')
                  .orderBy('purchaseDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun achat enregistré"));
                }

                final docs = snapshot.data!.docs;

                // 🔹 REGROUPEMENT PAR UTILISATEUR ET FILTRAGE
                final Map<String, List<Map<String, dynamic>>> grouped = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  if (statusFilter != 'all' && status != statusFilter) continue;

                  final uid = data['uid'];
                  if (uid == null) continue;

                  grouped.putIfAbsent(uid, () => []);
                  grouped[uid]!.add({...data, 'docId': doc.id});
                }

                if (grouped.isEmpty) {
                  return const Center(child: Text("Aucun achat trouvé"));
                }

                return ListView(
                  children: grouped.entries.map((entry) {
                    final uid = entry.key;
                    final purchases = entry.value;

                    final totalSpent = purchases.fold<int>(
                      0,
                      (sum, p) => sum + ((p['price'] ?? 0) as num).toInt(),
                    );

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text("Utilisateur: $uid"),
                        subtitle: Text("Achats: ${purchases.length}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Total"),
                            Text(
                              "$totalSpent FCFA",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserPurchasesDetailPage(
                                uid: uid,
                                purchases: purchases,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class AdminUserPurchasesDetailPage extends StatelessWidget {
  final String uid;
  final List<Map<String, dynamic>> purchases;

  const AdminUserPurchasesDetailPage({
    super.key,
    required this.uid,
    required this.purchases,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text("Achats utilisateur\n$uid"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final data = purchases[index];
          final date = data['purchaseDate']?.toDate();
          final status = data['status'] ?? 'pending';

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(data['productName'] ?? "Produit"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date != null)
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                  if (data['deliveryAddress'] != null)
                    Text("📍 ${data['deliveryAddress']}"),
                  const SizedBox(height: 4),
                  Text(
                    "Statut: $status",
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${data['price']} FCFA",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(purchase: data,),),);}, 
                      icon: const Icon(Icons.receipt_long)),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          db
                              .collection('purchases')
                              .doc(data['docId'])
                              .update({'status': value});
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'pending',
                            child: Text("⏳ En attente"),
                          ),
                          PopupMenuItem(
                            value: 'delivered',
                            child: Text("✅ Livré"),
                          ),
                          PopupMenuItem(
                            value: 'canceled',
                            child: Text("❌ Annulé"),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}