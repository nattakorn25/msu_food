import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';
import '../../widgets/menu_image.dart';
import 'order_track_screen.dart';

const _ordersCream = Color(0xFFFFFDF7);
const _ordersInk = Color(0xFF2D3142);
const _ordersTeal = Color(0xFF5D9C91);

/// ประวัติออเดอร์ทั้งหมดของลูกค้าคนนี้
///
/// รายการทั้งหน้าอัปเดตเองเมื่อร้านเปลี่ยนสถานะออเดอร์ใดก็ตาม
class MyOrdersScreen extends StatelessWidget {
  final User user;

  const MyOrdersScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final db = Db();
    final fmt = DateFormat('d/M/yyyy HH:mm');

    return Scaffold(
      backgroundColor: _ordersCream,
      appBar: AppBar(
        title: const Text('ประวัติการซื้อ'),
        backgroundColor: _ordersCream,
        foregroundColor: _ordersInk,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<FoodOrder>>(
        stream: db.watchMyOrders(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text('โหลดประวัติการซื้อไม่สำเร็จ'),
                    const SizedBox(height: 6),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: _ordersTeal,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ยังไม่มีประวัติการซื้อ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'เมื่อสั่งอาหาร รายการจะปรากฏที่หน้านี้',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = orders[i];
              // createdAt อาจเป็น null ชั่วคราวตอนที่ยังออฟไลน์
              // เพราะ serverTimestamp() จะได้ค่าจริงเมื่อถึงเซิร์ฟเวอร์
              final when = o.createdAt == null
                  ? 'กำลังส่งข้อมูล...'
                  : fmt.format(o.createdAt!);
              final statusLabel = OrderStatus.labels[o.status] ?? o.status;
              return Card(
                color: Colors.white,
                elevation: 0,
                shadowColor: _ordersInk.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFECE9E1)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: o.items.isNotEmpty
                      ? MenuImage(bytes: o.items.first.imageBytes, size: 48)
                      : const CircleAvatar(
                          backgroundColor: Color(0xFFE5F1EC),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: _ordersTeal,
                          ),
                        ),
                  title: Text(
                    o.shopName,
                    style: const TextStyle(
                      color: _ordersInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$when\n$statusLabel · ${o.items.length} รายการ',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${o.total} บาท',
                        style: const TextStyle(
                          color: _ordersInk,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: _ordersTeal,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackScreen(orderId: o.id),
                    ),
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
