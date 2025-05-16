import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => isLoading = true);

    try {
      // Firebase Authentication-р нэвтрэх
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception("Нэвтрэхэд алдаа гарлаа.");

      // Firestore дээрх админ эрхийг шалгах
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception("Та админ эрхгүй байна.");
      }

      // Амжилттай бол dashboard руу орох
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нэвтрэх алдаа: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ нэвтрэх')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Имэйл'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Имэйл буруу байна',
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Нууц үг'),
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Нууц үг доод тал нь 6 тэмдэгт',
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: loginAdmin,
                      child: const Text('Нэвтрэх'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
