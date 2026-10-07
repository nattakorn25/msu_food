import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final num price;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.available,
  });

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      available: data['available'] ?? true,
    );
  }
}