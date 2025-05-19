import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  String _searchText = '';
  String _searchType = 'userName';
  final List<String> _searchFields = ['userName', 'car', 'staffId', 'service', 'parts'];

  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, String> _staffUsernames = {};
  final String currentUserId = "ADMIN_UID"; // ← админы UID-г энд оруул

  @override
  void initState() {
    super.initState();
    _loadStaffUsernames();
  }

  Future<void> _loadStaffUsernames() async {
    final snapshot = await FirebaseFirestore.instance.collection('staffs').get();
    final map = <String, String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final uid = data['uid'];
      final username = data['username'];
      if (uid != null && username != null) {
        map[uid] = username;
      }
    }

    setState(() {
      _staffUsernames = map;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  bool _isAdmin() {
    return currentUserId == "ADMIN_UID"; // Энд админы UID-г ашигла
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Үйлчилгээний түүх'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: _searchType,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _searchType = value;
                        });
                      }
                    },
                    items: _searchFields.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(
                          field == 'userName'
                              ? 'Хэрэглэгч'
                              : field == 'car'
                                  ? 'Машины дугаар'
                                  : field == 'staffId'
                                      ? 'Ажилтан'
                                      : field == 'service'
                                          ? 'Үйлчилгээ'
                                          : 'Сэлбэг',
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Хайлт хийх утгаа оруулна уу',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('history')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Үйлчилгээний түүх алга.'));
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final field = (data[_searchType] ?? '').toString().toLowerCase();

                  final timestamp = data['date'];
                  final date = (timestamp is Timestamp) ? timestamp.toDate() : null;

                  final matchesSearch = field.contains(_searchText);
                  final matchesDate = _startDate == null ||
                      (_startDate != null &&
                          _endDate != null &&
                          date != null &&
                          !date.isBefore(_startDate!) &&
                          !date.isAfter(_endDate!));

                  return matchesSearch && matchesDate;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final staffId = data['staffId'];
                    final staffUsername = (staffId != null && _staffUsernames.containsKey(staffId))
                        ? _staffUsernames[staffId]!
                        : 'Тодорхойгүй';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.build, color: Colors.blue),
                        title: Text('${data['car']} - ${data['service']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Огноо: ${data['date'] != null ? (data['date'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : ''}'),
                            Text('Асуудал: ${data['issue'] ?? '-'}'),
                            Text('Хэрэглэгч: ${data['userName'] ?? '-'}'),
                            Text('Ажилтан: $staffUsername'),
                            Text('Сэлбэг: ${data['parts'] ?? '-'}'),
                            Text('Тоо: ${data['usedQuantity'] ?? '-'}'),
                          ],
                        ),
                        trailing: _isAdmin()
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('history')
                                      .doc(doc.id)
                                      .delete();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
