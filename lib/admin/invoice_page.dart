import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/admin/invoice_pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> purchase;

  const InvoicePage({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final date = purchase['purchaseDate']?.toDate();
    final total = purchase['price'] * purchase['quantity'];

    final whatsappText = """
🧾 FACTURE D’ACHAT

Client : ${purchase['userName']}
Produit : ${purchase['productName']}
Quantité : ${purchase['quantity'] ?? 0}
Prix unitaire : ${purchase['price']} FCFA
TOTAL : $total FCFA

Code de retrait : ${purchase['deliveryCode']}
""";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Facture"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ===== HEADER =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODO DELIVERY",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Facture officielle"),
                      ],
                    ),
                    if (date != null)
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),

                const Divider(height: 32),

                // ===== CLIENT INFO =====
                _infoRow("Client", purchase['userName'] ?? "indisponible"),
                _infoRow("Id", purchase['uid']),
                _infoRow("Numéro", purchase['userNumber'] ?? "indisponible"),
                _infoRow("Adresse", purchase['deliveryAddress'] ?? "Non définie"),

                const SizedBox(height: 20),

                // ===== TABLE HEADER =====
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text("Produit",style: TextStyle(fontWeight: FontWeight.bold),)),
                      Expanded(child: Text("Qté",style: TextStyle(fontWeight: FontWeight.bold),)),
                      Expanded(child: Text("Prix",style: TextStyle(fontWeight: FontWeight.bold),)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ===== PRODUCT LINE =====
                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(" ${purchase['productName']}", style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),)),
                    Expanded(child: Text("   ${purchase['quantity'] ?? ""}", style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),)),
                    Expanded(child: Text("${purchase['price']} F", style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),)),
                  ],
                ),

                const Divider(height: 32),

                // ===== TOTAL =====
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Total : $total FCFA",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Spacer(),

                // ===== FOOTER =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Code de retrait",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          purchase['deliveryCode'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // ===== QR CODE bottom right =====
                    QrImageView(
                      data: purchase['deliveryCode'],
                      size: 100,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== ACTION BUTTONS =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("PDF"),
                      onPressed: () async {
                        final pdfData =
                            await InvoicePdfService.generate(purchase);
                        await Printing.layoutPdf(
                          onLayout: (_) => pdfData,
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("WhatsApp"),
                      onPressed: () async {
                        final uri = Uri.parse(
                          "https://wa.me/?text=${Uri.encodeComponent(whatsappText)}",
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              "$label :",style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),)),
        ],
      ),
    );
  }
}