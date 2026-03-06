import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPromoPage extends StatefulWidget {
  const AddPromoPage({super.key});

  @override
  State<AddPromoPage> createState() => _AddPromoPageState();
}

class _AddPromoPageState extends State<AddPromoPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _linkProductController = TextEditingController();

  bool _isActive = true;
  bool _loading = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _addPromo() async {
    if (_titleController.text.isEmpty || _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Titre et Image sont obligatoires")));
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef = await _db.collection('promos').add({
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'linkProductId': _linkProductController.text.trim().isEmpty
            ? null
            : _linkProductController.text.trim(),
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Phase 1 : renommer promoId → id
      await docRef.update({'id': docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo ajoutée avec succès !")));

      _titleController.clear();
      _subtitleController.clear();
      _imageUrlController.clear();
      _linkProductController.clear();
      setState(() => _isActive = true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une promo")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: "Titre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                  labelText: "Sous-titre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                  labelText: "URL de l'image", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkProductController,
              decoration: const InputDecoration(
                  labelText: "ID du produit (optionnel)",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              title: const Text("Active"),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addPromo,
                    child: const Text("Ajouter la promo"),
                  ),
          ],
        ),
      ),
    );
  }
}