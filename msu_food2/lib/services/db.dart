import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';
import '../models/menu_item.dart';
import '../models/food_order.dart';

class Db {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _menu =>
      _db.collection('menuItems');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  // ---------- โปรไฟล์และบทบาท ----------
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((d) => d.exists ? d.data() : null);
  }

  Future<void> becomeCustomer(String uid, String name) async {
    await _users.doc(uid).set({
      'displayName': name,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> becomeShop(String uid, String name, String shopName) async {
    final batch = _db.batch();
    final shopRef = _shops.doc();

    batch.set(shopRef, {
      'name': shopName,
      'ownerId': uid,
      'isOpen': false,
      'orderCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_users.doc(uid), {
      'displayName': name,
      'role': 'shop',
      'shopId': shopRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ---------- ร้านค้า ----------
  Stream<Shop> watchShop(String shopId) =>
      _shops.doc(shopId).snapshots().map(Shop.fromDoc);

  Future<void> setShopOpen(String shopId, bool isOpen) async {
    await _shops.doc(shopId).update({
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Shop>> watchShops() => _shops
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Shop.fromDoc).toList());

  // ---------- เมนู (CRUD ครบ + รองรับ รูปภาพ Base64) ----------
  Stream<List<MenuItem>> watchMenu(String shopId) => _menu
      .where('shopId', isEqualTo: shopId)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(MenuItem.fromDoc).toList());

  /// CREATE เพิ่มเมนู พร้อมรูป (ถ้ามี)
  Future<void> addMenuItem(
    String shopId,
    String name,
    num price, {
    String? imageBase64, // ใหม่: รับรูปในรูปแบบ Base64
  }) async {
    await _menu.add({
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
      // ใส่ฟิลด์ imageBase64 เฉพาะเมื่อมีรูปเท่านั้น
      'imageBase64': ?imageBase64,
    });
  }

  /// UPDATE แก้ไขเมนู มีสามกรณีของรูป
  /// 1. imageBase64 != null -> เปลี่ยนเป็นรูปใหม่
  /// 2. removeImage == true -> ลบรูปเดิมออก (ลบฟิลด์ออกจาก Firestore)
  /// 3. ไม่ส่งทั้งสองค่า -> รูปเดิมคงอยู่
  Future<void> updateMenuItem(
    String id,
    String name,
    num price, {
    String? imageBase64,
    bool removeImage = false,
  }) async {
    await _menu.doc(id).update({
      'name': name.trim(),
      'price': price,
      'imageBase64': ?(
        imageBase64 ?? (removeImage ? FieldValue.delete() : null)
      ),
    });
  }

  // สลับสถานะมีของหรือของหมด
  Future<void> setAvailable(String id, bool value) async {
    await _menu.doc(id).update({'available': value});
  }

  Future<void> deleteMenuItem(String id) async {
    await _menu.doc(id).delete();
  }

  // ---------- ลูกค้าสั่งซื้อ ----------
  Future<String> placeOrder({
    required Shop shop,
    required String customerId,
    required String customerName,
    required List<OrderItem> items,
    required String note,
  }) async {
    final total = items.fold<num>(
      0,
      (runningTotal, item) => runningTotal + item.subtotal,
    );
    final batch = _db.batch();
    final orderRef = _orders.doc();

    batch.set(orderRef, {
      'shopId': shop.id,
      'shopName': shop.name,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': OrderStatus.pending,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return orderRef.id;
  }

  // ---------- การเฝ้าฟังออเดอร์ ----------
  Stream<List<FoodOrder>> watchShopOrders(String shopId) => _orders
      .where('shopId', isEqualTo: shopId)
      .where('status', whereIn: OrderStatus.active)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(FoodOrder.fromDoc).toList());

  Stream<List<FoodOrder>> watchShopHistory(String shopId) =>
      _orders.where('shopId', isEqualTo: shopId).snapshots().map((snapshot) {
        final orders = snapshot.docs.map(FoodOrder.fromDoc).toList();
        orders.sort((a, b) {
          final dateA = a.createdAt ?? DateTime(2000);
          final dateB = b.createdAt ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        return orders;
      });

  Stream<List<FoodOrder>> watchMyOrders(String uid) {
    return _orders.where('customerId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map((doc) => FoodOrder.fromDoc(doc))
          .toList();

      orders.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2000);
        final dateB = b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return orders;
    });
  }

  Stream<FoodOrder> watchOrder(String orderId) =>
      _orders.doc(orderId).snapshots().map(FoodOrder.fromDoc);

  // ---------- การเปลี่ยนสถานะ ----------
  Future<String?> acceptOrder(String orderId) async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('ไม่พบออเดอร์นี้');
        }
        if (snap.data()!['status'] != OrderStatus.pending) {
          throw Exception('ออเดอร์นี้ถูกจัดการไปแล้ว');
        }
        tx.update(ref, {
          'status': OrderStatus.accepted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> advanceStatus(String orderId, String current) async {
    final next = OrderStatus.next(current);
    if (next == null) return;
    await _orders.doc(orderId).update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status': OrderStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resetRole(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ---------- ตรวจสอบบทบาท ----------
  Future<String?> getUserRole(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    return data?['role'] as String?;
  }

  // ---------- ตรวจสอบรหัสร้าน ----------
  Future<String?> getUserShopId(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    return data?['shopId'] as String?;
  }
}