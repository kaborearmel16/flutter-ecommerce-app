import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// ================= PRODUIT PAGE =================
class ProduitPage extends StatefulWidget {
  const ProduitPage({super.key});

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  String filter = "all"; // all, actif, inactif, stock_pos, stock_zero
  String sort = "name_asc"; // name_asc, name_desc, price_asc, price_desc, stock_asc, stock_desc

  bool _applyFilter(Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? true;
    final stock = (data['stock'] ?? 0);
    switch (filter) {
      case 'actif':
        return isActive;
      case 'inactif':
        return !isActive;
      case 'stock_pos':
        return stock > 0;
      case 'stock_zero':
        return stock == 0;
      default:
        return true;
    }
  }

  List<DocumentSnapshot> _applySort(List<DocumentSnapshot> docs) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      switch (sort) {
        case 'name_asc':
          return (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
        case 'name_desc':
          return (dataB['name'] ?? '').compareTo(dataA['name'] ?? '');
        case 'price_asc':
          return (dataA['price'] ?? 0).compareTo(dataB['price'] ?? 0);
        case 'price_desc':
          return (dataB['price'] ?? 0).compareTo(dataA['price'] ?? 0);
        case 'stock_asc':
          return (dataA['stock'] ?? 0).compareTo(dataB['stock'] ?? 0);
        case 'stock_desc':
          return (dataB['stock'] ?? 0).compareTo(dataA['stock'] ?? 0);
        default:
          return 0;
      }
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produits"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith("tri_")) {
                  sort = value.replaceFirst("tri_", "");
                } else {
                  filter = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("Tous")),
              const PopupMenuItem(value: 'actif', child: Text("Actifs")),
              const PopupMenuItem(value: 'inactif', child: Text("Inactifs")),
              const PopupMenuItem(value: 'stock_pos', child: Text("Stock > 0")),
              const PopupMenuItem(value: 'stock_zero', child: Text("Stock = 0")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'tri_name_asc', child: Text("Nom ↑")),
              const PopupMenuItem(value: 'tri_name_desc', child: Text("Nom ↓")),
              const PopupMenuItem(value: 'tri_price_asc', child: Text("Prix ↑")),
              const PopupMenuItem(value: 'tri_price_desc', child: Text("Prix ↓")),
              const PopupMenuItem(value: 'tri_stock_asc', child: Text("Stock ↑")),
              const PopupMenuItem(value: 'tri_stock_desc', child: Text("Stock ↓")),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("products").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!.docs.where((doc) => _applyFilter(doc.data() as Map<String, dynamic>)).toList();
          final sortedProducts = _applySort(products);

          if (sortedProducts.isEmpty) return const Center(child: Text("Aucun produit"));

          return ListView.builder(
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final doc = sortedProducts[index];
              final id = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(data['productImages'] != null && (data['productImages'] as List).isNotEmpty ? data['productImages'][0] : data['imageUrl'] ?? '')),
                  title: Text(data['name'] ?? "Produit sans nom"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Prix: ${data['price'] ?? 0} FCFA"),
                      Text("Stock: ${data['stock'] ?? 0}"),
                      Text("Statut: ${isActive ? 'Actif' : 'Inactif'}"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProduitDetailPage(productId: id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAddProduct()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ================= PRODUIT DETAIL PAGE =================
class ProduitDetailPage extends StatelessWidget {
  final String productId;

  const ProduitDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Détails du produit")),
      body: FutureBuilder<DocumentSnapshot>(
        future: db.collection("products").doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Produit introuvable"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= INFORMATIONS =================
                _infoCard(
                  title: "Informations",
                  icon: Icons.shopping_bag,
                  color: Colors.blue,
                  children: [
                    Text("Nom: ${data['name'] ?? 'Non renseigné'}"),
                    Text("Prix: ${data['price'] ?? 0} FCFA"),
                    Text("Stock: ${data['stock'] ?? 0}"),
                    Text("Description: ${data['description'] ?? 'Aucune'}"),
                    Text("Statut: ${isActive ? 'Actif' : 'Inactif'}"),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= ACTIONS ADMIN =================
                _actionCard(context, productId, data),

                const SizedBox(height: 12),

                // ================= ACHATS =================
                StreamBuilder<QuerySnapshot>(
                  stream: db.collection("purchases").where("productId", isEqualTo: productId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final purchases = snapshot.data!.docs;
                    int delivered = 0, pending = 0, canceled = 0;
                    for (var p in purchases) {
                      final pData = p.data() as Map<String, dynamic>;
                      final status = pData['status'] ?? 'pending';
                      if (status == 'delivered') delivered++;
                      if (status == 'pending') pending++;
                      if (status == 'canceled') canceled++;
                    }
                    return _statCard(
                      title: "Achats complets",
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      stats: {
                        "Total": purchases.length.toString(),
                        "Livrés": delivered.toString(),
                        "En attente": pending.toString(),
                        "Annulés": canceled.toString(),
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ================= PAIEMENTS PROGRESSIFS =================
                StreamBuilder<QuerySnapshot>(
                  stream: db.collectionGroup("productPayments").where("productId", isEqualTo: productId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final payments = snapshot.data!.docs;
                    int completed = 0, partial = 0;
                    for (var p in payments) {
                      final pData = p.data() as Map<String, dynamic>;
                      final status = pData['status'] ?? 'partial';
                      if (status == 'completed') completed++;
                      if (status == 'partial') partial++;
                    }
                    return _statCard(
                      title: "Paiements progressifs",
                      icon: Icons.account_balance_wallet,
                      color: Colors.purple,
                      stats: {
                        "Total": payments.length.toString(),
                        "Complétés": completed.toString(),
                        "Partiels": partial.toString(),
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= WIDGET INFO =================
  Widget _infoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          ...children,
        ]),
      ),
    );
  }

  // ================= WIDGET STAT =================
  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, String> stats,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 12),
          ...stats.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(e.key), Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold))],
                ),
              )),
        ]),
      ),
    );
  }

  // ================= WIDGET ACTIONS =================
  Widget _actionCard(BuildContext context, String productId, Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Activer / Désactiver
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("products").doc(productId).update({'isActive': !isActive});
                },
                icon: Icon(isActive ? Icons.toggle_off : Icons.toggle_on),
                label: Text(isActive ? "Désactiver" : "Activer"),
              ),

              // Ajuster prix
              ElevatedButton.icon(
                onPressed: () async {
                  final TextEditingController controller = TextEditingController(text: (data['price'] ?? 0).toString());
                  final result = await showDialog<int>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Ajuster le prix"),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Nouveau prix"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                        TextButton(
                          onPressed: () {
                            final newPrice = int.tryParse(controller.text);
                            Navigator.pop(context, newPrice);
                          },
                          child: const Text("Valider"),
                        ),
                      ],
                    ),
                  );
                  if (result != null) {
                    await FirebaseFirestore.instance.collection("products").doc(productId).update({'price': result});
                  }
                },
                icon: const Icon(Icons.price_change),
                label: const Text("Ajuster prix"),
              ),

              // Modifier description / stock
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductPage(productId: productId),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Modifier"),
              ),

              // Supprimer produit
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirmer la suppression"),
                      content: const Text("Voulez-vous vraiment supprimer ce produit ?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection("products").doc(productId).delete();
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text("Supprimer"),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// =================== EDIT PRODUCT PAGE =================
// Ici tu peux réutiliser ton EditProductPage existant pour ajouter de nouveaux produits  

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _db = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _brandController = TextEditingController();
  final _imageController = TextEditingController();

  String? selectedTypeId;
  bool isOffer = false;
  bool isFeatured = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final doc = await _db.collection('products').doc(widget.productId).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produit introuvable")),
      );
      Navigator.pop(context);
      return;
    }

    final data = doc.data()!;
    _nameController.text = data['name'] ?? '';
    _priceController.text = (data['price'] ?? '').toString();
    _oldPriceController.text = (data['oldPrice'] ?? '').toString();
    _brandController.text = data['brand'] ?? '';
    _imageController.text = data['imageUrl'] ?? '';
    selectedTypeId = data['typeId'];
    isOffer = data['isOffer'] ?? false;
    isFeatured = data['isFeatured'] ?? false;

    setState(() => isLoading = false);
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _brandController.text.isEmpty ||
        _imageController.text.isEmpty ||
        selectedTypeId == null) return;

    try {
      await _db.collection('products').doc(widget.productId).update({
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text),
        'oldPrice': _oldPriceController.text.isEmpty
            ? null
            : int.parse(_oldPriceController.text),
        'brand': _brandController.text.trim(),
        'imageUrl': _imageController.text.trim(),
        'typeId': selectedTypeId,
        'isOffer': isOffer,
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produit mis à jour ✅")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      TextInputType type = TextInputType.text}) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le produit")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== NOM ET PRIX =====
            Row(
              children: [
                _buildTextField(controller: _nameController, label: "Nom"),
                const SizedBox(width: 12),
                _buildTextField(controller: _priceController, label: "Prix", type: TextInputType.number),
              ],
            ),
            const SizedBox(height: 12),

            // ===== ANCIEN PRIX ET MARQUE =====
            Row(
              children: [
                _buildTextField(controller: _oldPriceController, label: "Ancien prix", type: TextInputType.number),
                const SizedBox(width: 12),
                _buildTextField(controller: _brandController, label: "Marque"),
              ],
            ),
            const SizedBox(height: 12),

            // ===== IMAGE URL =====
            Row(
              children: [
                _buildTextField(controller: _imageController, label: "URL de l'image", type: TextInputType.url),
              ],
            ),
            const SizedBox(height: 12),

            // ===== TYPE DROPDOWN =====
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('types').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: selectedTypeId,
                  items: snapshot.data!.docs
                      .map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name'])))
                      .toList(),
                  onChanged: (val) => setState(() => selectedTypeId = val),
                  decoration: const InputDecoration(
                    labelText: "Type",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ===== SWITCH OFFRE & VEDETTE =====
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text("Offre spéciale"),
                      const SizedBox(width: 8),
                      Switch(value: isOffer, onChanged: (val) => setState(() => isOffer = val)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Text("Produit vedette"),
                      const SizedBox(width: 8),
                      Switch(value: isFeatured, onChanged: (val) => setState(() => isFeatured = val)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== BOUTON ENREGISTRER =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProduct,
                child: const Text("Enregistrer les modifications"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
 
class AdminAddProduct extends StatefulWidget {
  const AdminAddProduct({super.key});

  @override
  State<AdminAddProduct> createState() => _AdminAddProductState();
}

class _AdminAddProductState extends State<AdminAddProduct>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;

  // 📌 Controllers
  final _categoryController = TextEditingController();
  final _typeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productOldPriceController = TextEditingController();
  final _productBrandController = TextEditingController();
  final _productImagesController = TextEditingController(); // URL(s) séparées par virgule
  final _productStockController = TextEditingController();

  String? selectedCategoryId;
  String? selectedTypeId;

  bool isPromo = false;       // anciennement isOffer
  bool isFeatured = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  /// ➕ Ajouter catégorie
  Future<void> addCategory() async {
    if (_categoryController.text.isEmpty) return;
    await _db.collection('categories').add({
      'name': _categoryController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _categoryController.clear();
  }

  /// ➕ Ajouter type
  Future<void> addType() async {
    if (_typeController.text.isEmpty || selectedCategoryId == null) return;
    await _db.collection('types').add({
      'name': _typeController.text.trim(),
      'categoryId': selectedCategoryId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _typeController.clear();
  }

  /// ➕ Ajouter produit
  Future<void> addProduct() async {
    if (_productNameController.text.isEmpty ||
        _productPriceController.text.isEmpty ||
        _productBrandController.text.isEmpty ||
        _productImagesController.text.isEmpty ||
        _productStockController.text.isEmpty ||
        selectedTypeId == null) return;

    final typeDoc = await _db.collection('types').doc(selectedTypeId).get();
    if (!typeDoc.exists) throw Exception("Type introuvable");

    final categoryIdFromType = typeDoc['categoryId'];

    final docRef = await _db.collection('products').add({
      'name': _productNameController.text.trim(),
      'price': int.parse(_productPriceController.text),
      'oldPrice': _productOldPriceController.text.isEmpty
          ? null
          : int.parse(_productOldPriceController.text),
      'brand': _productBrandController.text.trim(),
      'images': _productImagesController.text
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
      'typeId': selectedTypeId,
      'categoryId': categoryIdFromType,
      'stock': int.parse(_productStockController.text),
      'isPromo': isPromo,        // corrigé Phase 1
      'isFeatured': isFeatured,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await docRef.update({'id': docRef.id});

    // Reset champs
    _productNameController.clear();
    _productPriceController.clear();
    _productOldPriceController.clear();
    _productBrandController.clear();
    _productImagesController.clear();
    _productStockController.clear();
    setState(() {
      isPromo = false;
      isFeatured = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Catégories"),
            Tab(text: "Types"),
            Tab(text: "Produits"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          /// ================== Onglet Catégories ==================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                      labelText: "Nom catégorie", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: addCategory, child: const Text("Ajouter catégorie")),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return ListTile(
                          title: Text(doc['name']),
                          subtitle: Text("ID: ${doc.id}"),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          /// ================== Onglet Types ==================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return DropdownButtonFormField<String>(
                      hint: const Text("Choisir catégorie"),
                      value: selectedCategoryId,
                      items: snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategoryId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                      labelText: "Nom du type", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: addType, child: const Text("Ajouter type")),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('types').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return ListTile(
                          title: Text(doc['name']),
                          subtitle: Text("Catégorie: ${doc['categoryId']}"),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          /// ================== Onglet Produits ==================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('types').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return DropdownButtonFormField<String>(
                      hint: const Text("Choisir type"),
                      value: selectedTypeId,
                      items: snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedTypeId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                      labelText: "Nom produit", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Prix", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productOldPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Ancien prix", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productBrandController,
                  decoration: const InputDecoration(
                      labelText: "Marque", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Stock", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _productImagesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: "URL image(séparées par virgule)", 
                      hintText: "http://img1.jpg, http://img2.jpg, ...",
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Text("Promo spéciale"),
                    Switch(
                        value: isPromo,
                        onChanged: (val) => setState(() => isPromo = val)),
                    const SizedBox(width: 20),
                    const Text("Produit en avant"),
                    Switch(
                        value: isFeatured,
                        onChanged: (val) => setState(() => isFeatured = val)),
                  ],
                ),

                const SizedBox(height: 12),
                ElevatedButton(onPressed: addProduct, child: const Text("Ajouter produit")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}