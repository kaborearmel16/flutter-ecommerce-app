import 'package:flutter/material.dart';
import 'package:todo_list/admin/admin_dashboard.dart';
import 'package:todo_list/pages/home.dart';
import 'package:todo_list/service/auth.dart';
import 'package:todo_list/service/user.dart';

class VerifiedEmailPage extends StatelessWidget {
  const VerifiedEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification e-mail")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Un e-mail de vérification a été envoyé.\nClique sur le lien pour activer votre compte.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                final userService = UserService();

                bool verified = await authService.checkEmailVerified();

                if (!verified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("E-mail non confirmé")),
                  );
                  return;
                }

                final role = await userService.getUserRole();

                if (role == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>  AdminDashboardPage(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                  );
                }
              },
              child: const Text("J'ai confirmé"),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () async {
                await AuthService().resendVerificationEmail();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("E-mail de vérification renvoyé"),
                  ),
                );
              },
              child: const Text("Renvoyer l’e-mail"),
            ),
          ],
        ),
      ),
    );
  }
}