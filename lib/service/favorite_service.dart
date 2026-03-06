import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> toggleFavorite({
  required String productId,
  required Map<String, dynamic> productData,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final favRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .collection('favorites')
      .doc(productId);

  final doc = await favRef.get();

  if (doc.exists) {
    await favRef.delete();
  } else {
    await favRef.set({
      'name': productData['name'],
      'price': productData['price'],
      'imageUrl': productData['imageUrl'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

Stream<bool> isFavorite(String productId) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .collection('favorites')
      .doc(productId)
      .snapshots()
      .map((doc) => doc.exists);
}