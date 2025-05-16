import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? selectedCarType;
  List<String> selectedSpareParts = [];
  final List<String> allCarTypes = ['Суудлын автомашин', 'Жийп'];
  List<String> allSpareParts = [];

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
  }

  Future<void> _loadSpareParts() async {
    final snapshot = await FirebaseFirestore.instance.collection('spareparts').get();
    setState(() {
      allSpareParts = snapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _saveService({String? docId}) async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isNotEmpty && price != null && selectedCarType != null) {
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'carType': selectedCarType,
        'spareParts': selectedSpareParts,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        await FirebaseFirestore.instance.collection('services').add(data);
      } else {
        await FirebaseFirestore.instance.collection('services').doc(docId).update(data);
      }

      nameController.clear();
      descriptionController.clear();
      priceController.clear();
      selectedCarType = null;
      selectedSpareParts.clear();
      Navigator.pop(context);
    }
  }

  void _showServiceDialog({Map<String, dynamic>? service, String? docId}) {
    if (service != null) {
      nameController.text = service['name'] ?? '';
      descriptionController.text = service['description'] ?? '';
      priceController.text = service['price']?.toString() ?? '';
      selectedCarType = service['carType'];
      selectedSpareParts = List<String>.from(service['spareParts'] ?? []);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(docId == null ? 'Үйлчилгээ нэмэх' : 'Үйлчилгээ засах'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Үйлчилгээний нэр')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Тайлбар')),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Үнэ (₮)')),
                DropdownButtonFormField<String>(
                  value: selectedCarType,
                  items: allCarTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => selectedCarType = val),
                  decoration: const InputDecoration(labelText: 'Машины төрөл'),
                ),
                Wrap(
                  spacing: 8,
                  children: allSpareParts.map((spare) {
                    final isSelected = selectedSpareParts.contains(spare);
                    return FilterChip(
                      label: Text(spare),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selected ? selectedSpareParts.add(spare) : selectedSpareParts.remove(spare);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Болих')),
            ElevatedButton(
              onPressed: () => _saveService(docId: docId),
              child: Text(docId == null ? 'Нэмэх' : 'Шинэчлэх'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteService(String docId) async {
    await FirebaseFirestore.instance.collection('services').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Үйлчилгээ устгалаа')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Үйлчилгээний жагсаалт'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showServiceDialog())],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Үйлчилгээ байхгүй байна.'));

          final services = snapshot.data!.docs;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index].data() as Map<String, dynamic>;
              final docId = services[index].id;

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('₮${data['price']?.toStringAsFixed(0) ?? "0"} | ${data['carType'] ?? ""}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showServiceDialog(service: data, docId: docId)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteService(docId)),
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
