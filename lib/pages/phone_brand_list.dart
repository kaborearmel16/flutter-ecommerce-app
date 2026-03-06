import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/pages/product_detail.dart';

class CategoryProductsPage extends StatelessWidget {
  final String categoryId; // Phase 1 : on filtre par categoryId
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('products');

    if (categoryId != "all") {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!.docs;

          if (products.isEmpty) return const Center(child: Text("Aucun produit"));

          // Regroupement par marque
          final brands = _groupByBrand(products);

          return ListView(
            children: brands.entries.map((entry) {
              return _BrandSection(
                brand: entry.key,
                products: entry.value,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupByBrand(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> map = {};
    for (final doc in docs) {
      final brand = doc['brand'] ?? "Autres";
      map.putIfAbsent(brand, () => []).add(doc);
    }
    return map;
  }
}

class _BrandSection extends StatelessWidget {
  final String brand;
  final List<QueryDocumentSnapshot> products;

  const _BrandSection({super.key, required this.brand, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            brand,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;
              return ProductCard(productId: doc.id, data: data);
            },
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;

  const ProductCard({super.key, required this.productId, required this.data});

  @override
  Widget build(BuildContext context) {
    final List images = data['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0] : '';
    final bool isPromo = data['isPromo'] ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productData: {"id": productId, ...data}),
            ),
          );
        },
        child: Container(
          width: 150,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(imageUrl, height: 100, fit: BoxFit.cover),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  data['name'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text("${data['price'] ?? 0} FCFA",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green)),
              if (isPromo)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "PROMO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}