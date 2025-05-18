// lib/widgets/sidebar.dart
import 'package:flutter/material.dart';
import '../screens/user_management_screen.dart';
import '../screens/staff_management_screen.dart';
import '../screens/service_management_screen.dart';
import '../screens/sparepart_management_screen.dart';
import '../screens/registeradminscreen.dart';
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int selectedIndex = -1;

  void _navigate(int index, Widget screen) {
    setState(() {
      selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Админ цэс', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Хэрэглэгчид'),
            selected: selectedIndex == 0,
            selectedTileColor: Colors.blue.shade100,
            onTap: () => _navigate(0, const UserManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Ажилтнууд'),
            selected: selectedIndex == 1,
            selectedTileColor: Colors.blue.shade100,
            onTap: () => _navigate(1, const StaffManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Үйлчилгээ'),
            selected: selectedIndex == 2,
            selectedTileColor: Colors.blue.shade100,
            onTap: () => _navigate(2, const ServiceManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.car_repair),
            title: const Text('Сэлбэг'),
            selected: selectedIndex == 3,
            selectedTileColor: Colors.blue.shade100,
            onTap: () => _navigate(3, const SparePartManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Админ бүртгэх'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterAdminScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
