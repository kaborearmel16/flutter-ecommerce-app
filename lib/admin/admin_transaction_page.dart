import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTransactionsPage extends StatelessWidget {
  const AdminTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('transactions').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) return const Center(child: Text("Aucune transaction"));

          // Calcul total des transactions
          final totalAmount = transactions.fold<int>(
            0,
            (previousValue, doc) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = data['amount'];
              if (amount is int) {
                return previousValue + amount;
              } else if (amount is double) {
                return previousValue + amount.toInt();
              }
              return previousValue; // ignore si null ou autre type
            },
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Total Transactions: $totalAmount FCFA",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final doc = transactions[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] ?? '';
                    final amount = data['amount'] ?? 0;
                    final uid = data['uid'] ?? '';
                    final date = (data['createdAt'] as Timestamp).toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: db.collection('Users').doc(uid).get(),
                      builder: (context, userSnap) {
                        String userEmail = uid;
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>;
                          userEmail = userData['email'] ?? uid;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: type == 'deposit' ? Colors.green : Colors.red,
                            ),
                            title: Text("$type - $amount FCFA"),
                            subtitle: Text("Utilisateur: $userEmail\nDate: ${date.toLocal()}"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminTransactionViewPage(transactionId: doc.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminTransactionViewPage extends StatelessWidget {
  final String transactionId;

  const AdminTransactionViewPage({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final transactionRef = db.collection('transactions').doc(transactionId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de la Transaction"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: transactionRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final type = data['type'] ?? '';
          final amount = data['amount'] ?? 0;
          final userUid = data['uid'] ?? '';
          final transactionUid = snapshot.data!.id;
          final date = (data['createdAt'] as Timestamp).toDate();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Type: $type", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Montant: $amount FCFA", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Utilisateur ID: $userUid", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Date: ${date.toLocal()}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Transaction ID: $transactionUid", style: const TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }
}