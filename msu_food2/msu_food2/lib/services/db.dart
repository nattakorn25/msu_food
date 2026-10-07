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
  // เฝ้าฟังเอกสารผู้ใช้ ใช้ตัดสินว่าจะพาไปหน้าจอของบทบาทใด
  // นี่คือตัวอย่างการฟัง "เอกสารเดียว" ไม่ใช่ทั้งคอลเลกชัน
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((d) => d.exists ? d.data() : null);
  }

  // เลือกบทบาทลูกค้า
  Future<void> becomeCustomer(String uid, String name) async {
    await _users.doc(uid).set({
      'displayName': name,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // เลือกบทบาทร้านค้า พร้อมสร้างเอกสารร้านในคราวเดียว
  // ใช้ batch เพื่อให้ทั้งสองเอกสารถูกเขียนสำเร็จพร้อมกัน
  // ถ้าเขียนทีละคำสั่ง แล้วคำสั่งที่สองล้มเหลว
  // จะได้ผู้ใช้ที่มีบทบาทร้านค้าแต่ไม่มีร้าน ซึ่งเป็นข้อมูลที่ผิด
  Future<void> becomeShop(String uid, String name, String shopName) async {
    final batch = _db.batch();
    final shopRef = _shops.doc(); // สร้างรหัสร้านล่วงหน้า

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

    await batch.commit(); // เขียนทั้งสองเอกสารพร้อมกัน
  }

  // ---------- ร้านค้า ----------
  // เฝ้าฟังเอกสารร้านเดียว ทั้งสองฝั่งใช้เมธอดนี้ร่วมกัน
  // ร้านใช้ดูสถานะของตน ลูกค้าใช้ดูว่าร้านยังเปิดอยู่หรือไม่
  Stream<Shop> watchShop(String shopId) =>
      _shops.doc(shopId).snapshots().map(Shop.fromDoc);

  // สลับสถานะเปิดปิดร้าน จุดสาธิตเรียลไทม์ข้อที่ 1
  Future<void> setShopOpen(String shopId, bool isOpen) async {
    await _shops.doc(shopId).update({
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // รายชื่อร้านทั้งหมด ลูกค้าเห็นทุกร้าน แต่กดสั่งได้เฉพาะร้านที่เปิด
  Stream<List<Shop>> watchShops() => _shops
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Shop.fromDoc).toList());

  // ---------- เมนู (CRUD ครบ) ----------
  Stream<List<MenuItem>> watchMenu(String shopId) => _menu
      .where('shopId', isEqualTo: shopId)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(MenuItem.fromDoc).toList());

  Future<void> addMenuItem(String shopId, String name, num price) async {
    await _menu.add({
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(String id, String name, num price) async {
    await _menu.doc(id).update({'name': name.trim(), 'price': price});
  }

  // สลับสถานะมีของหรือของหมด จุดสาธิตเรียลไทม์ข้อที่ 2
  Future<void> setAvailable(String id, bool value) async {
    await _menu.doc(id).update({'available': value});
  }

  Future<void> deleteMenuItem(String id) async {
    await _menu.doc(id).delete();
  }

  // ---------- ลูกค้าสั่งซื้อ ----------
  // ใช้ batch เพราะต้องเขียนสองเอกสารให้สำเร็จพร้อมกัน
  // คือ สร้างออเดอร์ใหม่ และเพิ่มตัวนับออเดอร์ของร้าน
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
      'shopName': shop.name, // เก็บซ้ำไว้ ไม่ต้องอ่านร้านอีก
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': OrderStatus.pending,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // increment ปลอดภัยกว่าอ่านค่าเดิมมาบวกเอง
    // เพราะถ้าลูกค้าหลายคนสั่งพร้อมกัน ค่าจะไม่หายไป
    batch.update(_shops.doc(shop.id), {'orderCount': FieldValue.increment(1)});

    await batch.commit();
    return orderRef.id;
  }

  // ---------- การเฝ้าฟังออเดอร์ ----------
  // ฝั่งร้าน: ออเดอร์ที่ยังทำงานอยู่ของร้านนี้
  // เรียงจากเก่าไปใหม่ เพราะออเดอร์ที่มาก่อนควรทำก่อน
  Stream<List<FoodOrder>> watchShopOrders(String shopId) => _orders
      .where('shopId', isEqualTo: shopId)
      .where('status', whereIn: OrderStatus.active)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(FoodOrder.fromDoc).toList());

  // ร้าน: ประวัติออเดอร์ทุกสถานะ เรียงใหม่ไปเก่า
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

  // ฝั่งลูกค้า: ออเดอร์ทั้งหมดของตนเอง ใหม่สุดอยู่บน
  Stream<List<FoodOrder>> watchMyOrders(String uid) {
    return _orders.where('customerId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map((doc) => FoodOrder.fromDoc(doc))
          .toList();

      // เรียงใหม่ -> เก่าใน Flutter
      orders.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2000);

        final dateB = b.createdAt ?? DateTime(2000);

        return dateB.compareTo(dateA);
      });

      return orders;
    });
  }

  // ฝั่งลูกค้า: ติดตามออเดอร์เดียวแบบละเอียด
  // นี่คือการฟังเอกสารเดียว ประหยัดกว่าฟังทั้งคอลเลกชันมาก
  Stream<FoodOrder> watchOrder(String orderId) =>
      _orders.doc(orderId).snapshots().map(FoodOrder.fromDoc);

  // ---------- การเปลี่ยนสถานะ ----------
  // ร้านกดรับออเดอร์ ใช้ธุรกรรมเพื่อกันการกดซ้ำ
  // สมมติว่าร้านเปิดแอปไว้สองเครื่องแล้วกดรับพร้อมกัน
  // ถ้าใช้ update() ธรรมดา คำสั่งหลังจะเขียนทับโดยไม่รู้ตัว
  // แต่ธุรกรรมจะอ่านค่าล่าสุดก่อนเขียน และยกเลิกถ้าเงื่อนไขไม่ตรง
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

  // เลื่อนไปยังสถานะถัดไปตามลำดับใน OrderStatus.flow
  Future<void> advanceStatus(String orderId, String current) async {
    final next = OrderStatus.next(current);
    if (next == null) return; // ไม่มีสถานะถัดไปแล้ว
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
