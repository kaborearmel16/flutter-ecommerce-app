import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatisticsPage extends StatelessWidget {
  const AdminStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveries =
        FirebaseFirestore.instance.collection('deliveryRequests');

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Statistiques"),
        backgroundColor: Colors.blueGrey[100],
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: deliveries.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final paid = docs.where((d) => d['paid'] == true).length;
          final unpaid = docs.where((d) => d['paid'] == false).length;

          final requested =
              docs.where((d) => d['status'] == 'requested').length;
          final assigned =
              docs.where((d) => d['status'] == 'assigned').length;
          final delivered =
              docs.where((d) => d['status'] == 'delivered').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _sectionTitle("Paiement des livraisons"),
                _barChart(paid, unpaid),
                const SizedBox(height: 24),
                _sectionTitle("Statut des livraisons"),
                _pieChart(requested, assigned, delivered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===============================
  // 📊 BAR CHART (PAYÉ / NON PAYÉ)
  // ===============================
  Widget _barChart(int paid, int unpaid) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  return Text(value == 0 ? "Payé" : "Non payé");
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: paid.toDouble(),
                color: Colors.green,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: unpaid.toDouble(),
                color: Colors.red,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              )
            ]),
          ],
        ),
      ),
    );
  }

  // ===============================
  // 🥧 PIE CHART (STATUS)
  // ===============================
  Widget _pieChart(int requested, int assigned, int delivered) {
    return SizedBox(
      height: 260,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            _pieSection("Demandées", requested, Colors.orange),
            _pieSection("Assignées", assigned, Colors.blue),
            _pieSection("Livrées", delivered, Colors.green),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _pieSection(
      String title, int value, Color color) {
    return PieChartSectionData(
      value: value.toDouble(),
      title: "$title\n$value",
      radius: 80,
      color: color,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}