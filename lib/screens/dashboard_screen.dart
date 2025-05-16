// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/topbar.dart';
import '../widgets/sidebar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),      // Дээд цэс
      drawer: const Sidebar(),     // Зүүн цэс
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.dashboard, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Админ Хяналтын Самбар',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Хэрэглэгч, ажилтан, үйлчилгээ, сэлбэгийн мэдээллийг хянаж болно.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
