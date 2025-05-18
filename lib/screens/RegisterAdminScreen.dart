import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '';
class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool loading = false;

  Future<void> _registerAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Firebase Authentication-д бүртгэх
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // Firestore дээр admins collection-д нэмэх
      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Админ амжилттай бүртгэгдлээ')),
      );

      // Sign out хийж буцаах
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ бүртгэх')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Нэр'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Имэйл'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Нууц үг'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _registerAdmin,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Бүртгэх'),
            ),
          ],
        ),
      ),
    );
  }
}
