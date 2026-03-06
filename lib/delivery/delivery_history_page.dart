import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  String filter = 'all';
  String searchQuery = '';
  late final String currentUserUid;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  }

  /// 🔎 Filtre uniquement par date (le livreur et le statut sont déjà filtrés côté Firestore)
  bool _applyDateFilter(Map<String, dynamic> data) {
    final date = data['deliveredAt']?.toDate();
    if (date == null) return false;

    final now = DateTime.now();

    switch (filter) {
      case 'day':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      default:
        return true;
    }
  }

  Color _statusColor(String status) {
    if (status == 'delivered') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Historique des livraisons"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[50],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// ===== FILTRES DATE =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton("Tous", "all"),
                  _filterButton("Aujourd'hui", "day"),
                  _filterButton("Ce mois", "month"),
                  _filterButton("Cette année", "year"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// ===== RECHERCHE =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black12,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Produit ou client",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (v) =>
                    setState(() => searchQuery = v.toLowerCase()),
              ),
            ),
            const SizedBox(height: 10),

            /// ===== LISTE HISTORIQUE =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('deliveryRequests')
                    .where('status', isEqualTo: 'delivered')
                    .where('assignedTo', isEqualTo: currentUserUid)
                    .orderBy('deliveredAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Erreur : ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final productName =
                        (data['productName'] ?? '').toString().toLowerCase();
                    final receiverName =
                        (data['receiverName'] ?? '').toString().toLowerCase();

                    final matchSearch = productName.contains(searchQuery) ||
                        receiverName.contains(searchQuery);

                    return _applyDateFilter(data) && matchSearch;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Aucune livraison trouvée"),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;
                      final date = data['deliveredAt']?.toDate();

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black12,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color: _statusColor(data['status']),
                          ),
                          title: Text(
                            data['productName'] ?? '—',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Client : ${data['receiverName'] ?? '—'}"),
                              if (date != null)
                                Text(
                                  "Livré le ${DateFormat('dd/MM/yyyy HH:mm').format(date)}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    final selected = filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => filter = value),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.blueGrey : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.blueGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}