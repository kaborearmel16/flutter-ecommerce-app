import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/delivery/delivery_dashboard_page.dart';
import 'package:todo_list/pages/login.dart';
import 'package:todo_list/pages/navigator_bar.dart';
import 'package:todo_list/pages/verified_email.dart';
import 'package:todo_list/admin/admin_dashboard.dart'; // <-- nouveau import

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Pas connecté
        if (!authSnapshot.hasData) {
          return LoginPage();
        }

        final user = authSnapshot.data!;

        // 📩 Email non vérifié
        if (!user.emailVerified) {
          return const VerifiedEmailPage();
        }

        // 🔥 Email vérifié → on regarde le rôle
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'user';

            // 🔹 Redirection selon rôle
            if (role == 'admin') {
              return AdminDashboardPage();
            } else if (role == 'delivery') {
              return const DeliveryDashboardPage();
            } else {
              return const NavigatorBar();
            }
          },
        );
      },
    );
  }
}