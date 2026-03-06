import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// ===============================
/// MODELE
/// ===============================
class DeliveryStats {
  final int today;
  final int month;
  final int year;
  final int total;
  final double earnings;
  final Map<String, int> lastMonthStatus; // paid / unpaid

  DeliveryStats({
    required this.today,
    required this.month,
    required this.year,
    required this.total,
    required this.earnings,
    required this.lastMonthStatus,
  });
}

/// ===============================
/// SERVICE
/// ===============================
class DeliveryStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DeliveryStats> fetchStats(String courierUid) async {
    final snapshot = await _db
        .collection('deliveryRequests')
        .where('assignedTo', isEqualTo: courierUid)
        .where('status', isEqualTo: 'delivered')
        .get();

    final now = DateTime.now();
    int today = 0;
    int month = 0;
    int year = 0;
    double earnings = 0;

    int paidLastMonth = 0;
    int unpaidLastMonth = 0;

    final lastMonth = DateTime(now.year, now.month - 1);

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['deliveredAt']?.toDate();
      final fee = (data['deliveryFee'] ?? 0).toDouble();
      final isPaid = data['paid'] ?? false;

      if (date == null) continue;
      earnings += fee;

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) today++;

      if (date.year == now.year && date.month == now.month) month++;
      if (date.year == now.year) year++;

      // Stats mois passé
      if (date.year == lastMonth.year && date.month == lastMonth.month) {
        if (isPaid) {
          paidLastMonth++;
        } else {
          unpaidLastMonth++;
        }
      }
    }

    return DeliveryStats(
      today: today,
      month: month,
      year: year,
      total: snapshot.docs.length,
      earnings: earnings,
      lastMonthStatus: {
        'paid': paidLastMonth,
        'unpaid': unpaidLastMonth,
      },
    );
  }
}

/// ===============================
/// PAGE UI
/// ===============================
class DeliveryStatsPage extends StatelessWidget {
  const DeliveryStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = DeliveryStatsService();

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Mes statistiques"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey[50],
      ),
      body: FutureBuilder<DeliveryStats>(
        future: service.fetchStats(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== GRAPHIQUE MOIS PASSÉ EN HAUT =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mois passé : Livraisons payées / non payées",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (stats.lastMonthStatus['paid']! +
                                    stats.lastMonthStatus['unpaid']!)
                                .toDouble() +
                                2,
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barsSpace: 6,
                                barRods: [
                                  BarChartRodData(
                                    toY:
                                        stats.lastMonthStatus['paid']!.toDouble(),
                                    color: Colors.green,
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: stats
                                        .lastMonthStatus['unpaid']!
                                        .toDouble(),
                                    color: Colors.red,
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ],
                                showingTooltipIndicators: [0, 1],
                              ),
                            ],
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final label =
                                      rodIndex == 0 ? 'Payé' : 'Non payé';
                                  return BarTooltipItem(
                                    "$label : ${rod.toY.toInt()}",
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          "Livraisons",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return const Text("");
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendCircle(Colors.green, "Payé"),
                          const SizedBox(width: 16),
                          _legendCircle(Colors.red, "Non payé"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ===== GRID STATISTIQUES =====
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    _statCard(Icons.today, "Aujourd'hui", "${stats.today}"),
                    _statCard(
                        Icons.calendar_month, "Ce mois", "${stats.month}"),
                    _statCard(Icons.event, "Cette année", "${stats.year}"),
                    _statCard(
                        Icons.check_circle, "Total livraisons", "${stats.total}"),
                    _statCard(
                        Icons.payments,
                        "Gains",
                        NumberFormat("#,##0", "fr_FR")
                                .format(stats.earnings) +
                            " FCFA",
                        isMoney: true),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ===============================
  /// WIDGETS
  /// ===============================
  Widget _statCard(IconData icon, String label, String value,
      {bool isMoney = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.blueGrey),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isMoney ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _legendCircle(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}