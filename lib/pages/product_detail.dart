import 'package:flutter/material.dart';
import 'package:todo_list/pages/product.dart';
import 'package:todo_list/service/favorite_service.dart';
import 'package:todo_list/service/product_paiement_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({
    super.key,
    required this.productData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  late Map<String, dynamic> product;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> productStream;

  @override
  void initState() {
    super.initState();
    product = Map<String, dynamic>.from(widget.productData);

    productStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productData['id'])
        .snapshots();

    quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(
        title: AutoSizeText(
          "Détails",
          style: TextStyle(fontSize: rf(context, 22), fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<bool>(
            stream: isFavorite(product['id']),
            builder: (context, snapshot) {
              final fav = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? Colors.red : Colors.black54,
                ),
                onPressed: () {
                  toggleFavorite(
                    productId: product['id'],
                    productData: product,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: productStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: AutoSizeText("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final p = {...product, ...snapshot.data!.data()!};

          final List<String> images = (p['images'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              (p['imageUrl'] != null ? [p['imageUrl']] : []);

          final int price = p['price'] ?? 0;
          final int? oldPrice = p['oldPrice'];
          final int stock = p['stock'] ?? 0;

          final bool isActive = p['isActive'] ?? true;
          final bool isOffer = p['isOffer'] ?? false;
          final bool isFeatured = p['isFeatured'] ?? false;

          final bool outOfStock = stock <= 0;
          final bool available = isActive && !outOfStock;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ================= IMAGES =================
                Stack(
                  children: [
                    SizedBox(
                      height: rh(context, 340),
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: rh(context, 15),
                      left: rw(context, 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFeatured) _badge("⭐ Vedette", Colors.deepPurple),
                          SizedBox(width: rw(context, 10)),
                          if (isOffer) _badge("🔥 Promo", Colors.red),
                        ],
                      ),
                    ),
                  ],
                ),

                // ================= CONTENT =================
                Container(
                  transform: Matrix4.translationValues(0, -25, 0),
                  padding: EdgeInsets.all(rw(context, 16)),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        p['name'],
                        style: TextStyle(
                          fontSize: rf(context, 24),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: rh(context, 12)),

                      // ===== PRICE CONTAINER =====
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(rw(context, 12)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(rw(context, 14)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxPriceWidth = constraints.maxWidth * 0.65;
                            final maxOldPriceWidth = constraints.maxWidth * 0.30;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center, 
                              children: [
                                Expanded(child: 
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isOffer ? maxPriceWidth : constraints.maxWidth,
                                  ),
                                  child: AutoSizeText(
                                    "$price FCFA",
                                    style: TextStyle(
                                      fontSize: rf(context, 20),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                                if (isOffer && oldPrice != null)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxOldPriceWidth,
                                    ),
                                    child: AutoSizeText(
                                      "$oldPrice FCFA",
                                      style: TextStyle(
                                        fontSize: rf(context, 16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Colors.red,
                                        decorationThickness: 3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      SizedBox(height: rh(context, 12)),

                      Row(
                        children: [
                          _infoChip(
                            outOfStock ? "Rupture ❌" : "Stock: $stock",
                            outOfStock ? Colors.red : Colors.green,
                          ),
                          SizedBox(width: rw(context, 10)),
                          _infoChip(
                            isActive ? "Actif" : "Désactivé",
                            isActive ? Colors.blue : Colors.grey,
                          ),
                        ],
                      ),

                      SizedBox(height: rh(context, 15)),

                      Container(
                        padding: EdgeInsets.all(rw(context, 14)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(rw(context, 14)),
                        ),
                        child: AutoSizeText(
                          p['description'] ?? 'Pas de description disponible.',
                          style: TextStyle(fontSize: rf(context, 15)),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: rh(context, 20)),

                      if (available)
                        Container(
                          padding: EdgeInsets.all(rw(context, 12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: AutoSizeText(
                                  "Quantité",
                                  style: TextStyle(
                                    fontSize: rf(context, 16),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                  minFontSize: 12,
                                  maxFontSize: 22,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.blue),
                                onPressed: () {
                                  if (quantity > 1) setState(() => quantity--);
                                },
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: rw(context, 18),
                                  vertical: rh(context, 8),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(rw(context, 12)),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: AutoSizeText(
                                  quantity.toString(),
                                  style: TextStyle(
                                    fontSize: rf(context, 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.blue),
                                onPressed: () {
                                  if (quantity < stock) {
                                    setState(() => quantity++);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                      if (available)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(rw(context, 12)),
                          child: Center(
                            child: AutoSizeText(
                              "Total : ${price * quantity} FCFA",
                              style: TextStyle(
                                fontSize: rf(context, 18),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),

                      SizedBox(height: rh(context, 15)),

                      if (!available)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(rw(context, 15)),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(rw(context, 14)),
                          ),
                          child: Center(
                            child: AutoSizeText(
                              !isActive
                                  ? "⛔ Produit désactivé"
                                  : "❌ Rupture de stock",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: rf(context, 16),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            _actionButton(
                              text: "Acheter maintenant",
                              color: Colors.green,
                              onTap: () async {
                                try {
                                  await ProductPaymentService().purchaseProduct(
                                    productId: p['id'],
                                    productName: p['name'],
                                    unitPrice: price,
                                    quantity: quantity,
                                    productImages: images,
                                    price: price * quantity,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Achat réussi 🎉"),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Erreur: $e")),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: rh(context, 10)),
                            _actionButton(
                              text: "Paiement progressif",
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductPage(
                                      productId: p['id'],
                                      productName: p['name'],
                                      unitPrice: price,
                                      quantity: quantity,
                                      productImages: images,
                                      productPrice: price * quantity,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= UI =================

  Widget _badge(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: rh(context, 6)),
      padding: EdgeInsets.symmetric(horizontal: rw(context, 12), vertical: rh(context, 6)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(rw(context, 20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)
        ],
      ),
      child: AutoSizeText(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        maxLines: 1,
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: rw(context, 12), vertical: rh(context, 6)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(rw(context, 20)),
        border: Border.all(color: color),
      ),
      child: AutoSizeText(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        maxLines: 1,
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
        padding: EdgeInsets.all(rw(context, 15)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(rw(context, 16)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: AutoSizeText(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  // ================= RESPONSIVE =================
  double rw(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return (v / 375) * w;
  }

  double rh(BuildContext context, double v) {
    final h = MediaQuery.of(context).size.height;
    return (v / 812) * h;
  }

  double rf(BuildContext context, double v) {
    final w = MediaQuery.of(context).size.width;
    return (v / 375) * w;
  }
}// font responsive
   