import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/pages/product.dart';

class MyProductsPage extends StatelessWidget {
  final String userId;

  const MyProductsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes produits"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('productPayments')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data!.docs;

          if (payments.isEmpty) {
            return const Center(child: Text("Aucun produit en cours"));
          }

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final doc = payments[index];
              final data = doc.data() as Map<String, dynamic>;

              final paidAmount = data['paidAmount'] ?? 0;
              final unlocked = data['unlocked'] ?? false;

              // Le prix du produit doit être récupéré depuis Firestore si nécessaire
              final productPrice = data['productPrice'] ?? 0; // idéalement stocké lors du premier dépôt
              final productName = data['productName'] ?? "Produit";
              final imageUrl = data['imageUrl'] ?? "";

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(productName),
                  subtitle: Text("Payé: $paidAmount / $productPrice FCFA\n${unlocked ? '✅ Débloqué' : '🔒 Verrouillé'}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductPage(
                          productId: doc.id,
                          productName: productName,
                          productPrice: productPrice,  
                          productImages: [imageUrl], 
                          unitPrice: data['unitPrice'] ?? 0, 
                          quantity: data['quantity'] ?? 1, // ✅ passer les images au service
                        ),
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