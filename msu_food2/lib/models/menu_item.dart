import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/image_service.dart';

class MenuItem {
  final String id;
  final String name;
  final num price;
  final bool available;
  final Uint8List? imageBytes;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.available,
    this.imageBytes,
  });

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      available: data['available'] ?? true,
      imageBytes: ImageService.decode(data['imageBase64'] as String?),
    );
  }
}