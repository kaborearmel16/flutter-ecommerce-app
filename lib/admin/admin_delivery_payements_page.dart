import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDeliveryPaymentPage extends StatelessWidget {
  const AdminDeliveryPaymentPage({super.key});

  static const int paymentPerDelivery = 1000;

  @override
  Widget build(BuildContext context) {
    final deliveries = FirebaseFirestore.instance.collection('deliveryRequests');
    final users = FirebaseFirestore.instance.collection('Users');

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Paiement des livreurs"),
        backgroundColor: Colors.blueGrey[100],
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: deliveries
            .where('status', isEqualTo: 'delivered')
            .where('isCourierPaid', isEqualTo: false) // 🔥 IMPORTANT
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("Aucun paiement en attente"),
            );
          }

          final Map<String, List<QueryDocumentSnapshot>> deliveriesByCourier = {};

          for (var d in docs) {
            final courierId = d['assignedTo'];
            deliveriesByCourier.putIfAbsent(courierId, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: deliveriesByCourier.entries.map((entry) {
              final courierId = entry.key;
              final courierDeliveries = entry.value;
              final count = courierDeliveries.length;
              final amount = count * paymentPerDelivery;

              return FutureBuilder<DocumentSnapshot>(
                future: users.doc(courierId).get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();

                  final u = snap.data!.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? 'Livreur',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Livraisons : $count"),
                          Text(
                            "Montant : $amount FCFA",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Payé"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final batch = FirebaseFirestore.instance.batch();

                                for (var d in courierDeliveries) {
                                  batch.update(d.reference, {
                                    'isCourierPaid': true,
                                    'paidAt': Timestamp.now(),
                                  });
                                }

                                await batch.commit();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Paiement effectué avec succès"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
 