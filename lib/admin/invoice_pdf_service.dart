import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class InvoicePdfService {
  static Future<Uint8List> generate(Map<String, dynamic> purchase) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "FACTURE D’ACHAT",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("Numéro : ${purchase['invoiceNumber'] ?? 'N/A'}"),
            pw.Text("Produit : ${purchase['productName'] ?? ''}"),
            pw.Text("Prix : ${purchase['price'] ?? 0} FCFA"),
            pw.Text("Quantité : ${purchase['quantity'] ?? 1}"),
            pw.Text("Statut : ${purchase['status'] ?? ''}"),
            pw.Text("Client : ${purchase['uid'] ?? ''}"),
            pw.Text("Adresse : ${purchase['deliveryAddress'] ?? 'Non définie'}"),

            pw.Divider(),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL : ${purchase['price'] ?? 0} FCFA",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}