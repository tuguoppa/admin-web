// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/topbar.dart';
import '../widgets/sidebar.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> serviceCounts = {};
  Map<String, double> sparePartsSales = {};

  @override
  void initState() {
    super.initState();
    _fetchServiceData();
    _fetchSparePartsData();
  }

  Future<void> _fetchServiceData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('services').get();
    Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final serviceName = doc['name'] ?? 'Тодорхойгүй';
      counts[serviceName] = (counts[serviceName] ?? 0) + 1;
    }
    setState(() {
      serviceCounts = counts;
    });
  }

  Future<void> _fetchSparePartsData() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('spareparts').get();
    Map<String, double> sales = {};
    for (var categoryDoc in snapshot.docs) {
      final itemsSnapshot =
          await categoryDoc.reference.collection('items').get();
      for (var item in itemsSnapshot.docs) {
        final partName = item['name'] ?? 'Тодорхойгүй';
        final sold = (item['sold'] ?? 0).toDouble();
        sales[partName] = (sales[partName] ?? 0) + sold;
      }
    }
    setState(() {
      sparePartsSales = sales;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.dashboard, size: 80, color: Colors.blue),
                    SizedBox(height: 20),
                    Text(
                      'Админ Хяналтын Самбар',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Хэрэглэгч, ажилтан, үйлчилгээ, сэлбэгийн мэдээллийг хянаж болно.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              _buildCardWithChart(
                context,
                title: 'Хэрэглэгчийн үйлчилгээний тоо',
                chart: _buildBarChart(),
                onTap: () => Navigator.pushNamed(context, '/service-summary'),
              ),
              const SizedBox(height: 16),
              _buildCardWithChart(
                context,
                title: 'Их борлуулагдсан сэлбэгүүд',
                chart: _buildPieChart(),
                onTap:
                    () => Navigator.pushNamed(context, '/spareparts-summary'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithChart(
    BuildContext context, {
    required String title,
    required Widget chart,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: chart),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onTap,
                child: const Text('Дэлгэрэнгүй'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final entries = serviceCounts.entries.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            (entries
                .map((e) => e.value)
                .fold(0, (a, b) => a > b ? a : b)).toDouble() +
            2,
        barGroups:
            entries.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value.value.toDouble(),
                    color: Colors.blue,
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPieChart() {
    final entries = sparePartsSales.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    return PieChart(
      PieChartData(
        sections:
            entries.map((e) {
              final percent =
                  total == 0 ? 0 : (e.value / total * 100).toStringAsFixed(1);
              return PieChartSectionData(
                value: e.value,
                title: '${e.key}\n$percent%',
                color:
                    Colors.primaries[entries.indexOf(e) %
                        Colors.primaries.length],
                radius: 60,
                titleStyle: const TextStyle(fontSize: 12),
              );
            }).toList(),
      ),
    );
  }
}
