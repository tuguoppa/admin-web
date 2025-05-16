import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SparePartManagementScreen extends StatefulWidget {
  const SparePartManagementScreen({super.key});

  @override
  State<SparePartManagementScreen> createState() => _SparePartManagementScreenState();
}

class _SparePartManagementScreenState extends State<SparePartManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController carTypeController = TextEditingController();
  final TextEditingController newCategoryController = TextEditingController();

  String? selectedCategory;
  List<String> dynamicCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('spareparts').get();
    setState(() {
      dynamicCategories = snapshot.docs.map((doc) => doc.id).toList();
      if (dynamicCategories.isNotEmpty && !dynamicCategories.contains(selectedCategory)) {
        selectedCategory = dynamicCategories.first;
      }
    });
  }

  Future<void> _addCategory() async {
    final newCategory = newCategoryController.text.trim();
    if (newCategory.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('spareparts')
        .doc(newCategory)
        .set({'createdAt': FieldValue.serverTimestamp()});

    newCategoryController.clear();
    await _loadCategories();
    setState(() {
      selectedCategory = newCategory;
    });
    Navigator.pop(context);
  }

  Future<void> _addSparePart() async {
    if (!_formKey.currentState!.validate()) return;

    final part = {
      'name': nameController.text.trim(),
      'carType': carTypeController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('spareparts')
        .doc(selectedCategory)
        .collection('items')
        .add(part);

    nameController.clear();
    priceController.clear();
    quantityController.clear();
    carTypeController.clear();

    Navigator.pop(context);
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ангилал нэмэх'),
        content: TextField(
          controller: newCategoryController,
          decoration: const InputDecoration(labelText: 'Ангиллын нэр'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Болих')),
          ElevatedButton(onPressed: _addCategory, child: const Text('Нэмэх')),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сэлбэг нэмэх'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: dynamicCategories
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => selectedCategory = value);
                        },
                        decoration: const InputDecoration(labelText: 'Ангилал'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _showAddCategoryDialog,
                    ),
                  ],
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Нэр'),
                  validator: (v) => v == null || v.isEmpty ? 'Нэр оруулна уу' : null,
                ),
                TextFormField(
                  controller: carTypeController,
                  decoration: const InputDecoration(labelText: 'Машины төрөл'),
                  validator: (v) => v == null || v.isEmpty ? 'Машины төрөл' : null,
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Үнэ'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Тоо ширхэг'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Болих')),
          ElevatedButton(onPressed: _addSparePart, child: const Text('Хадгалах')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сэлбэгийн бүртгэл')),
      body: ListView.builder(
        itemCount: dynamicCategories.length,
        itemBuilder: (context, index) {
          final cat = dynamicCategories[index];
          return ExpansionTile(
            title: Text(cat),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('spareparts')
                    .doc(cat)
                    .collection('items')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text('Машин: ${data['carType']} | ₮${data['price']} | Ширхэг: ${data['quantity']}'),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
