import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryType { courier, store }

class ProductPaymentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  // =====================================================
  // 🔐 DELIVERY CODE
  // =====================================================
  String generateDeliveryCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final code =
        List.generate(7, (_) => chars[rand.nextInt(chars.length)]).join();
    final year = DateTime.now().year;
    return 'DLV-$year-$code';
  }
 

  // =====================================================
  // ✅ ACHAT DIRECT
  // =====================================================
  Future<void> purchaseProduct({
    required String productId,
    required String productName,
    required int unitPrice,          // prix d’un seul produit
    required int quantity,           // quantité
    required List<String> productImages,
    required int price,              // prix total (optionnel mais conservé)
    }) async {
      if (user == null) throw Exception("Utilisateur non connecté");

      final totalPrice = unitPrice * quantity;

      final userRef = _db.collection('Users').doc(user!.uid);
      final productRef = _db.collection('products').doc(productId); // 👈 AJOUT
      final purchaseRef = _db.collection('purchases').doc();
      final deliveryCode = generateDeliveryCode();

      await _db.runTransaction((tx) async {
        // ===== USER =====
        final userSnap = await tx.get(userRef);
        if (!userSnap.exists) throw Exception("Utilisateur introuvable");

        final balance = (userSnap.data()?['balance'] ?? 0) as int;
        if (balance < totalPrice) throw Exception("Solde insuffisant");

        // ===== PRODUCT =====
        final productSnap = await tx.get(productRef);
        if (!productSnap.exists) throw Exception("Produit introuvable");

        final productData = productSnap.data() as Map<String, dynamic>;
        final int stock = productData['stock'] ?? 0;
        final bool isActive = productData['isActive'] ?? true;

        if (!isActive) throw Exception("Produit désactivé");
        if (stock < quantity) throw Exception("Stock insuffisant");

        // ===== UPDATES =====

        // 💰 Débit utilisateur
        tx.update(userRef, {
          'balance': balance - totalPrice,
        });

        // 📦 Décrément stock produit
        tx.update(productRef, {
          'stock': stock - quantity,
        });

        // 🧾 Enregistrement achat
        tx.set(purchaseRef, {
          'uid': user!.uid,
          'productId': productId,
          'productName': productName,
          'productImages': productImages,

          'unitPrice': unitPrice,
          'quantity': quantity,
          'totalPrice': totalPrice,

          'status': 'paid',
          'deliveryStatus': 'paid',
          'deliveryMode': null,

          'deliveryCode': deliveryCode,
          'assignedTo': null,

          'unlocked': true,
          'purchaseDate': FieldValue.serverTimestamp(),
        });

        // 📊 Historique transaction
        tx.set(_db.collection('transactions').doc(), {
          'uid': user!.uid,
          'amount': totalPrice,
          'type': 'purchase',
          'productId': productId,
          'quantity': quantity,
          'status': 'success',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    );
  }
  // =====================================================
  // 💳 PAIEMENT PROGRESSIF
  // =====================================================
  Future<bool> depositForProduct({
  required String productId,
  required String productName,
  required int unitPrice,        // prix unitaire
  required int quantity,         // 👈 quantité
  required int amount,           // montant du dépôt
  required List<String> productImages, required int productPrice,
  }) async {
    if (user == null) throw Exception("Utilisateur non connecté");

    final totalPrice = unitPrice * quantity;

    final userRef = _db.collection('Users').doc(user!.uid);
    final paymentRef = userRef.collection('productPayments').doc(productId);

    bool unlocked = false;
    final deliveryCode = generateDeliveryCode();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw Exception("Utilisateur introuvable");

      final paymentSnap = await tx.get(paymentRef);
      final balance = (userSnap.data()?['balance'] ?? 0) as int;
      if (balance < amount) throw Exception("Solde insuffisant");

      final paidAmount = paymentSnap.exists
          ? (paymentSnap.data()?['paidAmount'] ?? 0) as int
          : 0;

      final newPaid = paidAmount + amount;
      unlocked = newPaid >= totalPrice;

      tx.update(userRef, {'balance': balance - amount});

      tx.set(paymentRef, {
        'productId': productId,
        'productName': productName,

        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,

        'paidAmount': newPaid,
        'status': unlocked ? 'completed' : 'partial',
        'unlocked': unlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(_db.collection('transactions').doc(), {
        'uid': user!.uid,
        'amount': amount,
        'type': 'deposit',
        'productId': productId,
        'quantity': quantity,
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔓 Débloqué → création purchase
      if (unlocked) {
        tx.set(_db.collection('purchases').doc(), {
          'uid': user!.uid,
          'productId': productId,
          'productName': productName,
          'productImages': productImages,

          'unitPrice': unitPrice,
          'quantity': quantity,
          'totalPrice': totalPrice,

          'status': 'paid',
          'deliveryStatus': 'paid',
          'deliveryMode': null,

          'deliveryCode': deliveryCode,
          'assignedTo': null,

          'unlocked': true,
          'purchaseDate': FieldValue.serverTimestamp(),
        });
      }
    });

  return unlocked;
}

  // =====================================================
  // 🚚 DEMANDE LIVRAISON
  // =====================================================
  Future<void> requestCourierDelivery({
    required String purchaseId,
    required Map<String, dynamic> purchase,
    required String receiverName,
    required String receiverPhone,
    required String deliveryAddress, required String cnibNumber,
  }) async {
    if (user == null) throw Exception("Utilisateur non connecté");

    final batch = _db.batch();
    final deliveryRef = _db.collection('deliveryRequests').doc();

    batch.set(deliveryRef, {
      'purchaseId': purchaseId,
      'productId': purchase['productId'],
      'productName': purchase['productName'],
      'clientUid': user!.uid,
      'type': 'courier',
      'status': 'requested',
      'requestedAt': FieldValue.serverTimestamp(),
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'deliveryAddress': deliveryAddress,
      'paid': true,
      'assignedTo': null,
    });

    batch.update(_db.collection('purchases').doc(purchaseId), {
      'status': 'requested',
      'deliveryType': 'courier',
    });

    await batch.commit();
  }
 

  // =====================================================
  // 🚚 ASSIGNER LIVREUR
  // =====================================================
  Future<void> assignDeliveryToCourier({
    required String deliveryRequestId,
    required String courierUid,
  }) async {
    final ref = _db.collection('deliveryRequests').doc(deliveryRequestId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception("Demande inexistante");

    final data = snap.data()!;
    final purchaseId = data['purchaseId'];

    final batch = _db.batch();

    batch.update(ref, {
      'status': 'assigned',
      'assignedTo': courierUid,
      'assignedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('purchases').doc(purchaseId), {
      'status': 'assigned',
      'assignedTo': courierUid,
    });

    await batch.commit();
  }

  // =====================================================
  // ❌ ANNULATION LIVRAISON
  // =====================================================
  Future<void> cancelDeliveryRequest({required String purchaseId}) async {
    final q = await _db
        .collection('deliveryRequests')
        .where('purchaseId', isEqualTo: purchaseId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return;

    final batch = _db.batch();

    batch.delete(q.docs.first.reference);
    batch.update(_db.collection('purchases').doc(purchaseId), {
      'status': 'paid',
      'deliveryType': null,
      'assignedTo': null,
    });

    await batch.commit();
  }

  
  // =====================================================
  // ✅ CONFIRMATION LIVRAISON
  // =====================================================
  Future<void> confirmDelivery({
    required String purchaseId,
    required String receiverName,
    required String receiverPhone,
    required String cnibNumber,
    required String reference, required String deliveryRequestId,
  }) async {
    final query = await _db
        .collection('deliveryRequests')
        .where('purchaseId', isEqualTo: purchaseId)
        .where('deliveryType', isEqualTo: 'courier')
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception("Livraison introuvable");

    final deliveryDoc = query.docs.first;

    await _db.runTransaction((tx) async {
      tx.update(deliveryDoc.reference, {
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'cnibNumber': cnibNumber,
        'reference': reference,
      });

      tx.update(_db.collection('purchases').doc(purchaseId), {
        'status': 'delivered',
      });
    });
  }

  // =====================================================
}