import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/service/product_paiement_service.dart';

enum DeliveryFilter { all, unpaid, paid }

class AdminDeliveryRequestsPage extends StatefulWidget {
  const AdminDeliveryRequestsPage({super.key});

  @override
  State<AdminDeliveryRequestsPage> createState() =>
      _AdminDeliveryRequestsPageState();
}

class _AdminDeliveryRequestsPageState
    extends State<AdminDeliveryRequestsPage> {
  DeliveryFilter filter = DeliveryFilter.unpaid;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    Query query = db
        .collection('deliveryRequests')
        .orderBy('requestedAt', descending: true);

    if (filter == DeliveryFilter.paid) {
      query = query.where('paid', isEqualTo: true);
    } else if (filter == DeliveryFilter.unpaid) {
      query = query.where('paid', isEqualTo: false);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Demandes de livraison", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "produits assignés",
            icon: const Icon(Icons.assignment_ind),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminAssignedDeliveriesPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: "produits livrés",
            icon: const Icon(Icons.check_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDeliveredHistoryPage(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container( 
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey[700],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: _buildFilters(),
          ), 
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting){
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Erreur de chargement: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child:Text("Aucune donnée"));
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("Aucune demande"));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCounter(docs.length),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final d =
                              doc.data() as Map<String, dynamic>;

                          return _buildCard(context, doc.id, d);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // FILTRES (BOUTONS)
  // ===============================
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _filterButton("Tous", DeliveryFilter.all),
          _filterButton("Non payées", DeliveryFilter.unpaid),
          _filterButton("Payées", DeliveryFilter.paid),
        ],
      ),
    );
  }

  Widget _filterButton(String label, DeliveryFilter value) {
    final isActive = filter == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isActive ? Colors.blueGrey[900] : Colors.blueGrey[200],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () => setState(() => filter = value),
      child: Text(label),
    );
  }

  // ===============================
  // COMPTEUR
  // ===============================
  Widget _buildCounter(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      child: Text(
        "$count livraison(s)", 
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // ===============================
  // CARD LIVRAISON
  // ===============================
  Widget _buildCard(
      BuildContext context, String deliveryId, Map<String, dynamic> d) {
    final paid = d['paid'] == true;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(
          d['productName'] ?? 'Produit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
            Text("Tél : ${d['receiverPhone'] ?? '-'}"),
            Text("Lieu : ${d['deliveryAddress'] ?? '-'}"),
            const SizedBox(height: 6),
            Chip(
              label: Text(paid ? "PAYÉ" : "NON PAYÉ"),
              backgroundColor:
                  paid ? Colors.green[100] : Colors.red[100],
              labelStyle: TextStyle(
                color: paid ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: paid
            ? ElevatedButton(
                onPressed: () =>
                    _selectCourier(context, deliveryId: deliveryId),
                child: const Text("Assigner"),
              )
            : ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("payée"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    _confirmPaid(context, deliveryId: deliveryId),
              ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryDetailPage(
              deliveryId: deliveryId,
              data: d,
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // CONFIRMATION PAIEMENT
  // ===============================
  Future<void> _confirmPaid(
    BuildContext context, {
    required String deliveryId,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer"),
        content:
            const Text("Marquer cette livraison comme payée ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmer")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('deliveryRequests')
          .doc(deliveryId)
          .update({'paid': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Livraison soldée"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ===============================
  // SELECTION LIVREUR
  // ===============================
  void _selectCourier(
    BuildContext parentContext, {
    required String deliveryId,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'delivery')
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final couriers = snap.data!.docs;

            return ListView.builder(
              itemCount: couriers.length,
              itemBuilder: (context, i) {
                final doc = couriers[i];
                final u =
                    doc.data() as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.delivery_dining),
                  title: Text(u['name'] ?? 'Livreur'),
                  subtitle: Text(u['number'] ?? 'null'),
                  onTap: () async {
                    Navigator.pop(context);
                    try{
                      await ProductPaymentService()
                          .assignDeliveryToCourier(
                        deliveryRequestId: deliveryId,
                        courierUid: doc.id, 
                      );

                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text("Livreur assigné"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch(e){
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceFirst("Exception: ", "")),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class DeliveryDetailPage extends StatelessWidget {
  final String deliveryId;
  final Map<String, dynamic> data;

  const DeliveryDetailPage({
    super.key,
    required this.deliveryId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final paid = data['paid'] == true;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Détail de la livraison"),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== HEADER PRODUIT =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['productName'] ?? 'Produit',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          paid ? "PAYÉ" : "NON PAYÉ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor:
                            paid ? Colors.green[100] : Colors.red[100],
                        labelStyle: TextStyle(
                          color: paid
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (data['status'] != null)
                        Chip(
                          label: Text(
                            data['status'].toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.blueGrey[100],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== INFOS CLIENT =====
            _sectionCard(
              title: "Informations client",
              icon: Icons.person,
              children: [
                _infoRow("Nom", data['receiverName']),
                _infoRow("Téléphone", data['receiverPhone']),
              ],
            ),

            const SizedBox(height: 12),

            // ===== ADRESSE =====
            _sectionCard(
              title: "Adresse de livraison",
              icon: Icons.location_on,
              children: [
                _infoRow("Lieu", data['deliveryAddress']),
              ],
            ),

            const SizedBox(height: 12),

            // ===== LIVREUR =====
            _sectionCard(
              title: "Livreur",
              icon: Icons.delivery_dining,
              children: [
                _infoRow(
                  "Assigné à",
                  data['assignedTo'] != null
                      ? data['assignedTo']
                      : "Non assigné",
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== INFOS TECH =====
            _sectionCard(
              title: "Informations système",
              icon: Icons.info,
              children: [
                _infoRow("ID livraison", deliveryId),
                _infoRow("Payé", paid ? "Oui" : "Non"),
                _infoRow(
                  "Date",
                  data['requestedAt'] != null
                      ? (data['requestedAt'] as Timestamp)
                          .toDate()
                          .toString()
                      : "—",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // UI COMPONENTS
  // ===============================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "—",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 
 

class AdminAssignedDeliveriesPage extends StatefulWidget {
  const AdminAssignedDeliveriesPage({super.key});

  @override
  State<AdminAssignedDeliveriesPage> createState() =>
      _AdminAssignedDeliveriesPageState();
}

class _AdminAssignedDeliveriesPageState
    extends State<AdminAssignedDeliveriesPage> {

  String? selectedCourierId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    Query query = db
        .collection('deliveryRequests')
        .where('status', isEqualTo: 'assigned')
        .orderBy('assignedAt', descending: true);

    if (selectedCourierId != null) {
      query = query.where('assignedTo', isEqualTo: selectedCourierId);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Produits assignés"),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCourierFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun produit assigné"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_ind, color: Colors.blueGrey),
                        ),
                        title: Text(
                          d['productName'] ?? 'Produit',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Client : ${d['receiverPhone'] ?? '-'}"),
                            Text("Lieu : ${d['deliveryAddress'] ?? '-'}"),
                            const SizedBox(height: 4),
                            Text(
                              "Livreur : ${d['assignedToName'] ?? d['assignedTo'] ?? '—'}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // FILTRE LIVREUR
  // ===============================
  Widget _buildCourierFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'delivery')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final couriers = snap.data!.docs;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedCourierId,
                hint: const Text("Filtrer par livreur"),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("Tous les livreurs"),
                  ),
                  ...couriers.map((doc) {
                    final u = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String?>(
                      value: doc.id,
                      child: Text(u['name'] ?? 'Livreur'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCourierId = value;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminDeliveredHistoryPage extends StatefulWidget {
  const AdminDeliveredHistoryPage({super.key});

  @override
  State<AdminDeliveredHistoryPage> createState() =>
      _AdminDeliveredHistoryPageState();
}

class _AdminDeliveredHistoryPageState
    extends State<AdminDeliveredHistoryPage> {
  String? selectedCourierId;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    Query query = db
        .collection('deliveryRequests')
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true);

    if (selectedCourierId != null) {
      query = query.where('assignedTo', isEqualTo: selectedCourierId);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Historique des livraisons"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCourierFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucune livraison"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(d['productName'] ?? 'Produit'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client : ${d['receiverPhone'] ?? '-'}"),
                            Text("Livreur : ${d['assignedTo'] ?? '-'}"),
                            if (d['deliveredAt'] != null)
                              Text(
                                "Livré le : ${(d['deliveredAt'] as Timestamp).toDate()}",
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
    );
  }

  // ===============================
  // FILTRE LIVREUR
  // ===============================
  Widget _buildCourierFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'delivery')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final couriers = snap.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: selectedCourierId,
            hint: const Text("Filtrer par livreur"),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("Tous les livreurs"),
              ),
              ...couriers.map((doc) {
                final u = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(u['name'] ?? 'Livreur'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                selectedCourierId = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}