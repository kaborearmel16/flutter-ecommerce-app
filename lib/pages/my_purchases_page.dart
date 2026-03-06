// 🔽 IMPORTS IDENTIQUES 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:todo_list/admin/invoice_page.dart';
import 'package:todo_list/pages/delivery_request_page.dart';
import 'package:todo_list/service/product_paiement_service.dart';

class MyPurchasesPage extends StatefulWidget {
  const MyPurchasesPage({super.key});

  @override
  State<MyPurchasesPage> createState() => _MyPurchasesPageState();
}

class _MyPurchasesPageState extends State<MyPurchasesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final ProductPaymentService service = ProductPaymentService();

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Color _getCardColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green.shade50;
      case 'requested':
      case 'assigned':
        return Colors.orange.shade50;
      case 'paid':
      case 'partial':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Achats"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LivraisonDemade()),
              );
            },
          )
        ],
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Paiements en cours"),
            Tab(text: "Achats validés"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Rechercher produit",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() {
                searchQuery = v.toLowerCase();
              }),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [

                // ================= ONGLET 1 =================
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("Users")
                      .doc(uid)
                      .collection("productPayments")
                      .orderBy("updatedAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Aucun paiement en cours"));
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final p = doc.data() as Map<String, dynamic>;
                      final name =
                          (p['productName'] ?? '').toString().toLowerCase();
                      return !(p['unlocked'] ?? false) &&
                          name.contains(searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text("Aucun paiement en cours"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final p = docs[i].data() as Map<String, dynamic>;

                        final int paidAmount =
                            (p['paidAmount'] ?? 0) as int;
                        final int productPrice =
                            (p['productPrice'] ?? 1) as int;

                        final double progress =
                            productPrice > 0 ? paidAmount / productPrice : 0;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: _getCardColor('partial'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['productName'] ?? 'Produit',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Payé : $paidAmount / $productPrice FCFA",
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ================= ONGLET 2 =================
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("purchases")
                      .where("uid", isEqualTo: uid)
                      .orderBy("purchaseDate", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      final p = doc.data() as Map<String, dynamic>;
                      final name =
                          (p['productName'] ?? '').toString().toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final p = doc.data() as Map<String, dynamic>;

                        final String status = p['status'] ?? 'paid';
                        final String? deliveryType = p['deliveryType']; // null | courier | store

                        final bool isStorePickup = deliveryType == 'store';

                        final DateTime? date =
                            (p['purchaseDate'] as Timestamp?)?.toDate();

                        final bool delivered = status == 'delivered';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: _getCardColor(status),
                          child: ListTile(
                            title: Text(
                              p['productName'] ?? 'Produit',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deliveryType == null
                                      ? "Mode : Non défini"
                                      : isStorePickup
                                          ? "Mode : Retrait boutique"
                                          : "Mode : Livraison",
                                  style: TextStyle(
                                    color: isStorePickup
                                        ? Colors.blue
                                        : Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                delivered
                                    ? Text(
                                        "Validé le : ${date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : 'Inconnue'}",
                                      )
                                    : const Text("Payé"),
                              ],
                            ),
                            trailing: delivered
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : isStorePickup
                                    ? const Icon(Icons.store,
                                        color: Colors.blue)
                                    : deliveryType == null
                                        ? const Icon(Icons.help_outline,
                                            color: Colors.grey)
                                        : const Icon(Icons.local_shipping,
                                            color: Colors.orange),
                            onTap: () => _showPurchaseDialog(doc.id, p),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DIALOG =================
  void _showPurchaseDialog(String purchaseId, Map<String, dynamic> purchase) {
    final String status = purchase['status'] ?? 'paid';
    final String? deliveryType = purchase['deliveryType'];
    final bool delivered = status == 'delivered';
    final bool assigned = status == 'assigned';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ===== INDICATEUR =====
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ===== HEADER =====
              Row(
                children: [
                  const Icon(Icons.shopping_bag, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      purchase['productName'] ?? 'Produit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),

              // ===== INFOS =====
              _infoRow("Statut", status),
              _infoRow("Mode", deliveryType ?? "Non défini"),
              _infoRow("Prix", "${purchase['productPrice']} FCFA"),

              const SizedBox(height: 12),

              // ===== QR =====
              if (!delivered && purchase['deliveryCode'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: purchase['deliveryCode'],
                    size: 140,
                    backgroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 16),

              // ===== BOUTONS =====
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [

                  // 🔍 Détails
                  OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text("Détails"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(
                            purchaseId: purchaseId,
                            purchase: purchase,
                          ),
                        ),
                      );
                    },
                  ),

                  // 🧾 Facture
                  if (delivered)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text("Facture"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoicePage(
                              purchase: {...purchase, 'id': purchaseId},
                            ),
                          ),
                        );
                      },
                    ),

                  // 🚚 Livraison (uniquement si PAS assigné)
                  if (!assigned && !delivered && deliveryType != 'store')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text("Livraison"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryRequestPage(
                              purchaseId: purchaseId,
                              purchase: purchase,
                            ),
                          ),
                        );
                      },
                    ),

                   

                  // ❌ Annuler livraison
                  if (!assigned && deliveryType == 'courier')
                    TextButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Annuler livraison", style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        try {
                          await service.cancelDeliveryRequest(purchaseId: purchaseId);
                          Navigator.pop(context);
                        } catch (_) {}
                      },
                    ),

                  // ❌ Annuler boutique
                   
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  } 

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
 

// ================= PAGE DÉTAILS ACHAT ================= 

class ProductDetailsPage extends StatelessWidget {
  final String purchaseId;
  final Map<String, dynamic> purchase;

  const ProductDetailsPage({
    super.key,
    required this.purchaseId,
    required this.purchase, 
  });

  @override
  Widget build(BuildContext context) {
    final String name = purchase['productName'] ?? 'Produit';
    final String description = purchase['description'] ?? '';
    final int price = purchase['productPrice'] ?? 0;
    final String status = purchase['status'] ?? 'paid';
    final String? qrCode = purchase['deliveryCode'];
    final List images = purchase['productImages'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du produit"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ================= IMAGE ================= 
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: images.isNotEmpty
                              ? PageView.builder(
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final img = images[index];
                                    return Hero(
                                      tag: "$purchaseId-$index",
                                      child: Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (_, __, ___) {
                                          return const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 60, color: Colors.grey),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_not_supported,
                                            size: 60, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Aucune image",
                                            style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // ================= INFOS =================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "$price FCFA",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Badge statut
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= QR =================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Center(
                        child: status == 'assigned'
                            ? Column(
                                children: [
                                  QrImageView(
                                    data: qrCode ?? '',
                                    size: 180,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "QR de récupération du produit",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: const [
                                  Icon(Icons.lock_outline,
                                      size: 60, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    "Le produit doit être assigné\navant l’activation du QR",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.blue;
      case 'requested':
        return Colors.orange;
      case 'assigned':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
// ================= HISTORIQUE =================
class LivraisonDemade extends StatefulWidget {
  const LivraisonDemade({super.key});

  @override
  State<LivraisonDemade> createState() => _LivraisonDemandeState();
}

class _LivraisonDemandeState extends State<LivraisonDemade> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes demandes de livraison"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("deliveryRequests")
            .where("clientUid", isEqualTo: uid)
            .orderBy("requestedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;

              final String status = d['status'] ?? 'requested';
              final String productName = d['productName'] ?? 'Produit';

              return Card(
                child: ListTile(
                  title: Text(productName),
                  subtitle: Text("Statut : $status"),
                  trailing: const Icon(Icons.local_shipping),
                ),
              );
            },
          );
        },
      ),
    );
  }
}