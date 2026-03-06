import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/admin/admin_add_promo_page.dart';
import 'package:todo_list/admin/admin_delivered_request_page.dart';
import 'package:todo_list/admin/admin_delivery_payements_page.dart';
import 'package:todo_list/admin/admin_livreur.dart'; 
import 'package:todo_list/admin/admin_produit.dart';
import 'package:todo_list/admin/admin_statistique_page.dart';
import 'package:todo_list/admin/admin_transaction_page.dart';
import 'package:todo_list/admin/admin_users_purchases_page.dart'; 
import 'users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({super.key});

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- FUTURES ----------
  Future<int> _countCollection(String name) async {
    final snap = await _db.collection(name).get();
    return snap.size;
  }

  Future<int> _countTransactionsByStatus(String status) async {
    final snap = await _db
        .collection("transactions")
        .where("status", isEqualTo: status)
        .get();
    return snap.size;
  }

  Future<int> _outOfStockProducts() async {
    final snap = await _db
        .collection("products")
        .where("stock", isEqualTo: 0)
        .get();
    return snap.size;
  }

  Future<int> _totalWalletBalance() async {
    final snap = await _db.collection("Users").get();
    int total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['balance'] ?? 0) as int;
    }
    return total;
  }

  // ---------- DRAWER ----------
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  // ---------- STAT CARD ----------
  Widget _statCard({
    required String title,
    required Future<int> future,
    required IconData icon,
    required Color color,
    String suffix = "",
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                "$value$suffix",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  "Menu Admin",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            _drawerItem(context, icon: Icons.dashboard, title: "Dashboard", page: AdminDashboardPage()),
            _drawerItem(context, icon: Icons.people, title: "Utilisateurs", page: const UsersPage()), 
            _drawerItem(context, icon: Icons.shopping_bag, title: "Produit", page: const ProduitPage()),
            _drawerItem(context, icon: Icons.swap_horiz, title: "Transactions", page: const AdminTransactionsPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "achat", page: const AdminUsersPurchasesPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "livraison", page: const AdminDeliveryRequestsPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "Payement", page: const AdminDeliveryPaymentPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "Statistique", page: const AdminStatisticsPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "courier", page: const CouriersPage()),
            _drawerItem(context, icon: Icons.shopping_cart, title: "Promo", page: const AddPromoPage()),

          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _statCard(
                title: "Utilisateurs",
                future: _countCollection("Users"),
                icon: Icons.people,
                color: Colors.blue),
            _statCard(
                title: "Produits",
                future: _countCollection("products"),
                icon: Icons.shopping_bag,
                color: Colors.green),
            _statCard(
                title: "Rupture stock",
                future: _outOfStockProducts(),
                icon: Icons.warning,
                color: Colors.orange),
            _statCard(
                title: "Transactions réussies",
                future: _countTransactionsByStatus("success"),
                icon: Icons.check_circle,
                color: Colors.teal),
            _statCard(
                title: "Transactions échouées",
                future: _countTransactionsByStatus("failed"),
                icon: Icons.cancel,
                color: Colors.red),
            _statCard(
                title: "Solde total",
                future: _totalWalletBalance(),
                icon: Icons.account_balance_wallet,
                color: Colors.purple,
                suffix: " FCFA"),
          ],
        ),
      ),
    );
  }
}