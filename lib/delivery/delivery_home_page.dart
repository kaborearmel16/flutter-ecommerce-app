import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:todo_list/delivery/delivery_validate_page.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  bool isProcessing = false;
  late final String currentUserUid;

  int remainingDeliveries = 0;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.blueGrey[50],
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showScannerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Scanner le QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
        content: SizedBox(
          height: 200,
          child: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                Navigator.pop(context);
                _handleScan(barcode.rawValue!);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleScan(String code) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      // 1️⃣ Récupérer le purchase correspondant au code
      final purchaseQuery = await FirebaseFirestore.instance
          .collection('purchases')
          .where('deliveryCode', isEqualTo: code)
          .limit(1)
          .get();

      if (purchaseQuery.docs.isEmpty) {
        _showDialog("QR invalide", "Ce QR n'existe pas.");
        return;
      }

      final purchaseDoc = purchaseQuery.docs.first;
      final purchaseData = purchaseDoc.data();

      // 2️⃣ Vérifier le statut
      if (purchaseData['status'] == 'delivered') {
        _showDialog("Déjà livré", "Cette livraison est déjà effectuée.");
        return;
      }

      if (purchaseData['assignedTo'] != currentUserUid) {
        _showDialog("Accès refusé", "Cette livraison ne vous est pas attribuée.");
        return;
      }

      // 3️⃣ Récupérer le deliveryRequestId correspondant
      final deliveryQuery = await FirebaseFirestore.instance
          .collection('deliveryRequests')
          .where('purchaseId', isEqualTo: purchaseDoc.id)
          .limit(1)
          .get();

      if (deliveryQuery.docs.isEmpty) {
        _showDialog("Erreur", "Aucune demande de livraison trouvée pour ce produit.");
        return;
      }

      final deliveryRequestId = deliveryQuery.docs.first.id;

      // 4️⃣ Naviguer vers la page de validation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryValidatePage(
            purchaseId: purchaseDoc.id,
            purchase: purchaseData,
            deliveryRequestId: deliveryRequestId, // <- indispensable pour confirmer
          ),
        ),
      );
    } catch (e) {
      _showDialog("Erreur", "Une erreur est survenue : $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],

      // ===== APPBAR =====
      appBar: AppBar(
        title: const Text("Livraisons", style: TextStyle(fontWeight: FontWeight.bold),), 
        backgroundColor: Colors.blueGrey[50],
        elevation: 0,
        actions: [
          // 🔄 Actualiser
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: "Actualiser",
            onPressed: () => setState(() {}),
          ),

          // 🤖 Assistant
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.black,),
            tooltip: "Assistant",
            onPressed: () {},
          ),
        ],
      ),

      // ===== SCANNER =====
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: _showScannerDialog,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),

      // ===== BODY =====
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ===== ESPACE LIVRAISONS RESTANTES =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    "Livraisons restantes : ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    remainingDeliveries.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ===== LISTE DES LIVRAISONS =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('purchases')
                    .where('status', isEqualTo: 'assigned')
                    .where('assignedTo', isEqualTo: currentUserUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  remainingDeliveries = docs.length;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Aucune livraison attribuée"),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final p = doc.data() as Map<String, dynamic>;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black12,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.local_shipping,
                            color: Colors.blueGrey,
                          ),
                          title: Text(
                            p['productName'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(p['deliveryAddress']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryDetailProduit(
                                  purchaseId: doc.id, 
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
            ),
          ],
        ),
      ),
    );
  }
} 


class DeliveryDetailProduit extends StatelessWidget {
  final String purchaseId;

  const DeliveryDetailProduit({
    super.key,
    required this.purchaseId,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          "Détail livraison",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: db.collection('purchases').doc(purchaseId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Livraison introuvable"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>; 

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(
                  icon: Icons.shopping_bag,
                  title: "Produit",
                  value: data['productName'] ?? '—',
                ),

                _infoCard(
                  icon: Icons.person,
                  title: "Client",
                  value: data['receiverName'] ?? '—',
                ),

                _infoCard(
                  icon: Icons.phone,
                  title: "Téléphone",
                  value: data['receiverPhone'] ?? '—',
                ),

                _infoCard(
                  icon: Icons.location_on,
                  title: "Adresse",
                  value: data['deliveryAddress'] ?? '—',
                ),

                _infoCard(
                  icon: Icons.info,
                  title: "Statut",
                  value: data['status'] ?? '—',
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(2, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}