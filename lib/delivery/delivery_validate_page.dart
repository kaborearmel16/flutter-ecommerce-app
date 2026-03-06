import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_list/service/product_paiement_service.dart';

class DeliveryValidatePage extends StatefulWidget {
  final String deliveryRequestId;
  final String purchaseId;
  final Map<String, dynamic> purchase;

  const DeliveryValidatePage({
    super.key,
    required this.deliveryRequestId,
    required this.purchaseId,
    required this.purchase,
  });

  @override
  State<DeliveryValidatePage> createState() => _DeliveryValidatePageState();
}

class _DeliveryValidatePageState extends State<DeliveryValidatePage> {
  final receiverNameCtrl = TextEditingController();
  final receiverPhoneCtrl = TextEditingController();
  final cnibCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    receiverNameCtrl.text = widget.purchase['receiverName'] ?? '';
    receiverPhoneCtrl.text = widget.purchase['receiverPhone'] ?? '';
  }

  Future<void> _confirmDelivery() async {
    if (receiverNameCtrl.text.isEmpty ||
        receiverPhoneCtrl.text.isEmpty ||
        cnibCtrl.text.isEmpty ||
        referenceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ProductPaymentService().confirmDelivery(
        deliveryRequestId: widget.deliveryRequestId,
        purchaseId: widget.purchaseId,
        reference: referenceCtrl.text,
        receiverName: receiverNameCtrl.text,
        receiverPhone: receiverPhoneCtrl.text,
        cnibNumber: cnibCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Livraison confirmée")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
    final productImageUrl = p['productImage'];

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Valider la livraison"),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard("Produit : ${p['productName']}"),
            _infoCard("Prix : ${p['price']} FCFA"),
            _infoCard("Code livraison : ${p['deliveryCode']}"),

            const SizedBox(height: 16),

            // IMAGE PRODUIT
            _sectionTitle("Aperçu du produit"),
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey),
              ),
              child: productImageUrl == null || productImageUrl.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 40),
                          SizedBox(height: 8),
                          Text("Aucune image disponible"),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        productImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
            ),

            _sectionTitle("Informations du receveur"),
            _buildTextField("Nom du receveur", receiverNameCtrl),
            const SizedBox(height: 10),
            _buildTextField("Téléphone", receiverPhoneCtrl, isNumber: true),
            const SizedBox(height: 10),
            _buildTextField("Numéro CNIB", cnibCtrl, isNumber: true),
            const SizedBox(height: 10),
            _buildTextField("Référence livraison", referenceCtrl),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CONFIRMER LA LIVRAISON",
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

  Widget _infoCard(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget _buildTextField(String label, TextEditingController controller,
          {bool isNumber = false}) =>
      TextField(
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