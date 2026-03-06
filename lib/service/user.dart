import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Mettre à jour le profil utilisateur
  Future<void> userProfil(String name, String quartier) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection("Users").doc(user.uid).update({
      'nom': name,
      'résidence': quartier,
    });
  }

  /// Stream des données utilisateur
  Stream<DocumentSnapshot> userStream() {
    final uid = _auth.currentUser!.uid;
    return _db.collection("Users").doc(uid).snapshots();
  }

  /// 🔹 Nouvelle méthode : récupérer le rôle ('admin' ou 'user')
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection("Users").doc(user.uid).get();
    final data = doc.data();
    if (!doc.exists) return null;
    if (data  == null) return null;

    return data['role'] as String?; // retourne 'admin' ou 'user'
  }
}