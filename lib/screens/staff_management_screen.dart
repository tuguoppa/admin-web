import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:math';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String? generatedPassword;
  String? editingId;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    positionController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  String _generateRandomPassword({int length = 8}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _saveStaff() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final position = positionController.text.trim();
    final username = usernameController.text.trim();

    if ([name, email, phone, position, username].any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')));
      return;
    }

    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Утасны дугаар 8 оронтой байх ёстой'))
  );
  return;
}

    final password = generatedPassword ?? _generateRandomPassword();
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    try {
      UserCredential credential;

      if (editingId == null) {
        // Firebase Authentication дээр ажилтан үүсгэх
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final staffData = {
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'position': position,
          'username': username,
          'password': hashedPassword,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('staffs').doc(credential.user!.uid).set(staffData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ажилтан амжилттай бүртгэгдлээ. Нууц үг: $password')));
      } else {
        final staffData = {
          'name': name,
          'email': email,
          'phone': phone,
          'position': position,
          'username': username,
        };

        await FirebaseFirestore.instance.collection('staffs').doc(editingId).update(staffData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ажилтан шинэчлэгдлээ')));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Алдаа: $e')));
    }
  }

  void _showStaffDialog({Map<String, dynamic>? staff, String? docId}) {
    if (staff != null) {
      nameController.text = staff['name'] ?? '';
      emailController.text = staff['email'] ?? '';
      phoneController.text = staff['phone'] ?? '';
      positionController.text = staff['position'] ?? '';
      usernameController.text = staff['username'] ?? '';
      editingId = docId;
      generatedPassword = null;
    } else {
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      positionController.clear();
      usernameController.clear();
      generatedPassword = _generateRandomPassword();
      editingId = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editingId == null ? 'Ажилтан бүртгэх' : 'Ажилтан засах'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Нэр')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Имэйл')),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Утас'),
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Албан тушаал')),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Нэвтрэх нэр')),
              if (generatedPassword != null && editingId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Нууц үг: $generatedPassword', style: const TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Болих')),
          ElevatedButton(onPressed: _saveStaff, child: const Text('Хадгалах')),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(String docId) async {
    await FirebaseFirestore.instance.collection('staffs').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ажилтан устгалаа')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ажилтны бүртгэл'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showStaffDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('staffs').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Ажилтан байхгүй байна.'));
          }

          final staffList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index].data() as Map<String, dynamic>;
              final docId = staffList[index].id;

              return ListTile(
                title: Text('${staff['name']} (${staff['position']})'),
                subtitle: Text('${staff['email']} • ${staff['phone']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showStaffDialog(staff: staff, docId: docId)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteStaff(docId)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
