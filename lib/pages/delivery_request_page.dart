import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_list/service/product_paiement_service.dart';

class DeliveryRequestPage extends StatefulWidget {
  final String purchaseId;
  final Map<String, dynamic> purchase;

  const DeliveryRequestPage({
    super.key,
    required this.purchaseId,
    required this.purchase,
  });

  @override
  State<DeliveryRequestPage> createState() => _DeliveryRequestPageState();
}

class _DeliveryRequestPageState extends State<DeliveryRequestPage> {
  final receiverNameCtrl = TextEditingController();
  final receiverPhoneCtrl = TextEditingController();
  final cnibCtrl = TextEditingController();
  final deliveryLocationCtrl = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    receiverNameCtrl.text = widget.purchase['receiverName'] ?? '';
    receiverPhoneCtrl.text = widget.purchase['receiverPhone'] ?? '';
    cnibCtrl.text = widget.purchase['cnibNumber'] ?? '';
    deliveryLocationCtrl.text = widget.purchase['deliveryAddress'] ?? '';
  }

  Future<void> _submitRequest() async {
    if (receiverNameCtrl.text.isEmpty ||
        receiverPhoneCtrl.text.isEmpty ||
        cnibCtrl.text.isEmpty ||
        deliveryLocationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Veuillez remplir tous les champs")),
      );
      return;
    }

    if (widget.purchase['status'] == 'delivery_requested') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📦 Livraison déjà demandée")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ProductPaymentService().requestCourierDelivery(
        purchaseId: widget.purchaseId,
        purchase: widget.purchase,
        receiverName: receiverNameCtrl.text,
        receiverPhone: receiverPhoneCtrl.text,
        cnibNumber: cnibCtrl.text,
        deliveryAddress: deliveryLocationCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Livraison demandée avec succès")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Demande de livraison"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Nom du receveur", receiverNameCtrl, false),
            const SizedBox(height: 10),
            _buildTextField("Téléphone", receiverPhoneCtrl, true),
            const SizedBox(height: 10),
            _buildTextField("Numéro CNIB", cnibCtrl, false),
            const SizedBox(height: 10),
            _buildTextField("Lieu de livraison", deliveryLocationCtrl, false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "VALIDER LA DEMANDE",
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Champs stylisés =====
  Widget _buildTextField(
      String label, TextEditingController controller, bool isNumber) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}