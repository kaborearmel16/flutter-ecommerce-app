import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupérer le solde actuel
  Future<int> getBalance() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final doc = await _db.collection("Users").doc(user.uid).get();
    final data = doc.data();

    return (data?['balance'] ?? 0) as int;
  }

  /// Déposer de l'argent dans le portefeuille
  Future<void> deposit(int amount) async {
    if (amount <= 0) throw Exception("Montant invalide");

    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    final userRef = _db.collection("Users").doc(user.uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? {};
      final currentBalance = data['balance'] ?? 0;

      // Mise à jour du solde
      transaction.update(userRef, {'balance': currentBalance + amount});

      // Ajouter la transaction
      transaction.set(
        _db.collection('transactions').doc(),
        {
          'uid': user.uid,
          'amount': amount,
          'type': 'deposit',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }
}