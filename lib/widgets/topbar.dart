// lib/widgets/topbar.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../screens/admin_login_screen.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Админ Хяналтын Самбар"),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseService.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            );
          },
        ),
      ],
    );
  }
}
