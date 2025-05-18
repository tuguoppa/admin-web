import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Хэрэглэгчийн бүртгэл хянах'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Хэрэглэгч олдсонгүй.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final docId = users[index].id;
              final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';

              return ListTile(
                title: Text(name),
                subtitle: Text(user['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Хэрэглэгч устгалаа')),
                    );
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailsScreen(userId: docId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Дэлгэрэнгүй мэдээлэл')),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Нэр: ${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'),
                Text('Имэйл: ${userData['email'] ?? ''}'),
                Text('Утас: ${userData['phone'] ?? ''}'),
                const SizedBox(height: 20),
                const Text('Засварын түүх', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: userDoc.collection('history').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Засварын түүх байхгүй байна');
                      }

                      final history = snapshot.data!.docs;

                      return ListView(
                        children: history.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['service'] ?? 'Үйлчилгээ нэргүй'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Гэмтэл: ${data['issue'] ?? 'Байхгүй'}'),
                                Text('Сэлбэг: ${data['parts'] ?? 'Байхгүй'}'),
                                Text('Огноо: ${data['date'] ?? ''}'),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
