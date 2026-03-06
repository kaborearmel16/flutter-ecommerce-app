import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_list/admin/invoice_page.dart';
import 'package:todo_list/delivery/delivery_validate_page.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboard> {
  bool isProcessing = false;
  String filter = 'all';
  String searchQuery = '';
  late final String currentUserUid;

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
              child: const Text("OK")),
        ],
      ),
    );
  }

  bool _filterPurchase(Map<String, dynamic> p) {
    final date = p['deliveredAt']?.toDate();
    if (date == null) return false;
    if (p['deliveredBy'] != currentUserUid) return false;

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

  Color _getCardColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange.shade100;
      case 'delivered':
        return Colors.green.shade100;
      default:
        return Colors.blue.shade50;
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'assigned':
        color = Colors.orange;
        text = 'Attribué';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Livré';
        break;
      default:
        color = Colors.blueGrey;
        text = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("livreur"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[50],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScannerDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white,),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ===== Filtre =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton('Tous', 'all'),
                  _filterButton('Aujourd\'hui', 'day'),
                  _filterButton('Ce mois', 'month'),
                  _filterButton('Cette année', 'year'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ===== Recherche =====
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher produit / client',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            ),
            const SizedBox(height: 8),

            // ===== Liste =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('purchases')
                    .orderBy('deliveredAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((doc) {
                    final p = doc.data() as Map<String, dynamic>;
                    return _filterPurchase(p) &&
                        (p['productName'].toString().toLowerCase().contains(searchQuery) ||
                            (p['receiverName'] ?? '').toString().toLowerCase().contains(searchQuery));
                  }).toList();

                  if (docs.isEmpty) return const Center(child: Text("Aucune livraison trouvée"));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final p = doc.data() as Map<String, dynamic>;
                      final date = p['deliveredAt']?.toDate();

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCardColor(p['status']),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(2, 2))],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping, color: Colors.blueGrey),
                          title: Text(p['productName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (date != null)
                                Text("Livré le ${DateFormat('dd/MM/yyyy HH:mm').format(date)}"),
                              if (p['receiverName'] != null) Text("Receveur : ${p['receiverName']}"),
                            ],
                          ),
                          trailing: _statusBadge(p['status']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoicePage(purchase: {...p, 'id': doc.id}),
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

  Widget _filterButton(String label, String value) {
    final selected = filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => filter = value),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.blueGrey : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.blueGrey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }

  void _showScannerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Scanner le QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
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
    isProcessing = true;

    final query = await FirebaseFirestore.instance.collection('purchases').where('deliveryCode', isEqualTo: code).limit(1).get();

    if (query.docs.isEmpty) {
      isProcessing = false;
      _showDialog("QR invalide", "Ce QR n'existe pas.");
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();

    if (data['status'] == 'delivered') {
      isProcessing = false;
      _showDialog("Livré", "Cette livraison est déjà effectuée.");
      return;
    }

    if (data['assignedTo'] != currentUserUid) {
      isProcessing = false;
      _showDialog("Accès refusé", "Cette livraison ne vous est pas attribuée.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryValidatePage(purchaseId: doc.id, purchase: data, deliveryRequestId: '',)),
    ).then((_) => setState(() => isProcessing = false));
  }
}