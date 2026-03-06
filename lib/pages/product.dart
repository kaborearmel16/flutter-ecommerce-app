import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_list/pages/my_purchases_page.dart'; 
import 'package:todo_list/service/product_paiement_service.dart';

class ProductPage extends StatefulWidget {
  final String productId;
  final String productName;
  final int productPrice;
  final List<String> productImages;
  final int unitPrice;
  final int quantity;

  const ProductPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImages,
    required this.unitPrice,
    required this.quantity,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  int enteredAmount = 0;
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final productPaymentRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .collection("productPayments")
        .doc(widget.productId);

    return StreamBuilder<DocumentSnapshot>(
      stream: productPaymentRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final paidAmount = data?['paidAmount'] ?? 0;
        final unlocked = data?['unlocked'] ?? false;

        final progress = (paidAmount / widget.productPrice).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),

          // ================= APPBAR =================
          appBar: AppBar(
            elevation: 2,
            centerTitle: true,
            leading: const Icon(Icons.storefront),

            title: Column(
              children: [
                Text(widget.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  unlocked ? "Produit débloqué" : "Paiement progressif",
                  style: TextStyle(
                    fontSize: 12,
                    color: unlocked ? Colors.green.shade900 : Colors.orangeAccent,
                  ),
                ),
              ],
            ),

            actions: [
              // Badge statut
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: unlocked ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    unlocked ? "Débloqué" : "En cours",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),

              // Sécurité
              IconButton(
                icon: const Icon(Icons.verified_user),
                onPressed: () { 
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Sécurité & Paiements"),
                          content: const Text(
                            "Vos paiements sont sécurisés 🔒\n"
                            "Vous pouvez payer en plusieurs fois sans frais supplémentaires.\n"
                            "Une fois le paiement total effectué, votre produit sera débloqué instantanément 🎉\n"
                            "En cas de problème, contactez notre support client."
                          ), 
                          actions: [  
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Fermer"),
                            ),
                          ],
                        ),
                      ); 
                },
              ),
            ],
          ),

          // ================= BODY =================
          body: Center(
            child: Container(
              width: isDesktop(context)
                  ? 650
                  : isTablet(context)
                      ? 520
                      : double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ===== TITLE =====
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===== PRICE INFO =====
                        _infoRow("Prix total", "${widget.productPrice} FCFA"),
                        _infoRow("Montant payé", "$paidAmount FCFA"),
                        _infoRow("Restant", "${widget.productPrice - paidAmount} FCFA"),

                        const SizedBox(height: 20),

                        // ===== PROGRESS =====
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Progression du paiement",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade300,
                                color: unlocked ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${(progress * 100).toStringAsFixed(1)} %",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ===== STATUS =====
                        if (unlocked)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Center(
                              child: Text(
                                "✅ Produit totalement débloqué",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // ===== ACTION ZONE =====
                        if (!unlocked)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const Text(
                                "Montant à payer",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Entrer le montant",
                                  prefixIcon: const Icon(Icons.payments),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    enteredAmount = int.tryParse(value) ?? 0;
                                  });
                                },
                              ),

                              const SizedBox(height: 16),

                              _actionButton(
                                text: "Payer maintenant",
                                color: Colors.blue,
                                onTap: () async {
                                  if (enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Entre un montant valide")),
                                    );
                                    return;
                                  }

                                  if (enteredAmount > (widget.productPrice - paidAmount)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Montant supérieur au restant à payer")),
                                    );
                                    return;
                                  }

                                  try {
                                    final unlockedNow =
                                        await ProductPaymentService().depositForProduct(
                                      productId: widget.productId,
                                      productName: widget.productName,
                                      productPrice: widget.productPrice,
                                      amount: enteredAmount,
                                      productImages: widget.productImages,
                                      unitPrice: widget.unitPrice,
                                      quantity: widget.quantity,
                                    );

                                    _amountController.clear();
                                    setState(() => enteredAmount = 0);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          unlockedNow
                                              ? "Produit débloqué 🎉"
                                              : "Paiement effectué avec succès",
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _actionButton(
                                text: "Redémarrer le paiement",
                                color: Colors.orange,
                                onTap: () async {
                                  await productPaymentRef.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Nouveau paiement progressif démarré"),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _actionButton(
                                text: "Voir achats", 
                                color: Colors.green, 
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => const MyPurchasesPage()));
                                })
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= UI COMPONENTS =================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}