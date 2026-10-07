import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String name;
  final num price;
  final int qty;

  OrderItem({required this.name, required this.price, required this.qty});

  num get subtotal => price * qty;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      qty: map['qty'] ?? 1,
    );
  }
}

class OrderStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const cooking = 'cooking';
  static const ready = 'ready';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const active = [pending, accepted, cooking, ready];
  static const flow = [pending, accepted, cooking, ready, completed];

  static const labels = {
    pending: 'รอรับออเดอร์',
    accepted: 'รับออเดอร์แล้ว',
    cooking: 'กำลังปรุงอาหาร',
    ready: 'อาหารพร้อมส่ง/รับ',
    completed: 'เสร็จสิ้น',
    cancelled: 'ยกเลิกแล้ว',
  };

  static String? actionLabel(String status) {
    switch (status) {
      case pending:
        return 'รับออเดอร์';
      case accepted:
        return 'เริ่มทำอาหาร';
      case cooking:
        return 'อาหารเสร็จแล้ว';
      case ready:
        return 'ส่งมอบเรียบร้อย';
      default:
        return null;
    }
  }

  static String? next(String status) {
    final i = flow.indexOf(status);
    if (i != -1 && i + 1 < flow.length) return flow[i + 1];
    return null;
  }
}

class FoodOrder {
  final String id;
  final String shopId;
  final String shopName;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final num total;
  final String status;
  final String note;
  final DateTime? createdAt;

  FoodOrder({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.note,
    this.createdAt,
  });

  factory FoodOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final list = (data['items'] as List<dynamic>?) ?? [];
    return FoodOrder(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      items: list.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      total: data['total'] ?? 0,
      status: data['status'] ?? OrderStatus.pending,
      note: data['note'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}