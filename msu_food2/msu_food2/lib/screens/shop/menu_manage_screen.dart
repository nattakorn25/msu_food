import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/db.dart';

class MenuManageScreen extends StatelessWidget {
  final String shopId;

  const MenuManageScreen({super.key, required this.shopId});

  void _showAddDialog(BuildContext context, Db db) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มเมนูใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่ออาหาร'),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ราคา (บาท)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final price = num.tryParse(priceCtrl.text) ?? 0;
              if (nameCtrl.text.isNotEmpty && price > 0) {
                db.addMenuItem(shopId, nameCtrl.text, price);
                Navigator.pop(ctx);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการเมนูอาหาร')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, db),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: db.watchMenu(shopId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('กด + เพื่อเพิ่มเมนูแรกของคุณ'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              return ListTile(
                title: Text(m.name),
                subtitle: Text('${m.price} บาท'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: m.available,
                      onChanged: (val) => db.setAvailable(m.id, val),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => db.deleteMenuItem(m.id),
                    ),
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