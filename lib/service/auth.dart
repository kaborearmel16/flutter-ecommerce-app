import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> signUp({required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = cred.user!;

      // Envoi du lien de vérification
      await user.sendEmailVerification();

      // Sauvegarde de l'utilisateur dans Firestore
      final uid = user.uid;
      await _db.collection("Users").doc(uid).set({
        "email": email,
        "balance": 0,
        "emailVerified": false,
        "createdAt": FieldValue.serverTimestamp(),
        "role": 'user'
      });
    } on FirebaseAuthException catch (e) {
      print("Erreur lors de l'inscription: ${e.message}");
      rethrow; // pour propager l'erreur si besoin
    }
  }

  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    bool verified = _auth.currentUser!.emailVerified;

    // Synchroniser avec Firestore
    if (verified) {
      await _db.collection("Users").doc(user.uid).update({
        "emailVerified": true,
      });
    }

    return verified;
  }

  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      print("Erreur lors de la connexion: ${e.message}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}