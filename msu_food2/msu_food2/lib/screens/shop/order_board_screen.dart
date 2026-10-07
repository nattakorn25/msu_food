import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../models/shop.dart';
import '../../services/db.dart';
import 'menu_manage_screen.dart';
import 'history.dart';
import 'shop_profile_screen.dart';

class OrderBoardScreen extends StatelessWidget {
  final User user;
  final String shopId;

  const OrderBoardScreen({super.key, required this.user, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return StreamBuilder<Shop>(
      stream: db.watchShop(shopId),
      builder: (context, shopSnap) {
        final shop = shopSnap.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),

          // =====================================================
          // APP BAR
          // =====================================================
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,

            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),

            title: Text(
              shop?.name ?? 'จัดการร้านค้า',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            actions: [
              // -----------------------------------------------
              // ปุ่มจัดการเมนู
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'ประวัติ',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(shopId: shopId),
                    ),
                  );
                },
              ), // -----------------------------------------------
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'โปรไฟล์',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopProfileScreen(shopId: shopId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                tooltip: 'จัดการเมนู',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManageScreen(shopId: shopId),
                    ),
                  );
                },
              ),
            ],
          ),

          // =====================================================
          // BODY
          // =====================================================
          body: Column(
            children: [
              // =================================================
              // การ์ดเปิด / ปิดร้าน
              // =================================================
              if (shop != null)
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: SwitchListTile(
                    secondary: Icon(
                      shop.isOpen
                          ? Icons.storefront
                          : Icons.storefront_outlined,
                      color: shop.isOpen ? Colors.green : Colors.grey,
                      size: 28,
                    ),

                    title: Text(
                      shop.isOpen ? 'ร้านเปิดอยู่' : 'ร้านปิดอยู่',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: shop.isOpen
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),

                    subtitle: Text(
                      shop.isOpen
                          ? 'กำลังรับออเดอร์จากลูกค้า'
                          : 'ปิดรับออเดอร์ชั่วคราว',
                      style: const TextStyle(fontSize: 12),
                    ),

                    value: shop.isOpen,

                    activeThumbColor: Colors.green,

                    onChanged: (value) {
                      db.setShopOpen(shopId, value);
                    },
                  ),
                ),

              // =================================================
              // หัวข้อออเดอร์
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.deepOrange),

                    const SizedBox(width: 8),

                    const Text(
                      'ออเดอร์ของร้าน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    if (shop != null)
                      Text(
                        shop.isOpen ? 'เปิดรับออเดอร์' : 'ปิดรับออเดอร์',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: shop.isOpen ? Colors.green : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // =================================================
              // รายการออเดอร์
              // =================================================
              Expanded(
                child: StreamBuilder<List<FoodOrder>>(
                  stream: db.watchShopOrders(shopId),

                  builder: (context, snap) {
                    // ---------------------------------------------
                    // Error
                    // ---------------------------------------------

                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.redAccent,
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'เกิดข้อผิดพลาด:\n${snap.error}',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // ---------------------------------------------
                    // Loading
                    // ---------------------------------------------

                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      );
                    }

                    final orders = snap.data!;

                    // ---------------------------------------------
                    // ไม่มีออเดอร์
                    // ---------------------------------------------

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 72,
                              color: Colors.grey[400],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'ไม่มีออเดอร์ค้างอยู่',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'เมื่อมีลูกค้าสั่งอาหาร\nออเดอร์จะแสดงที่หน้านี้',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ---------------------------------------------
                    // แสดงออเดอร์
                    // ---------------------------------------------

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),

                      itemCount: orders.length,

                      itemBuilder: (context, index) {
                        final o = orders[index];

                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.08),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),

                          margin: const EdgeInsets.only(bottom: 12),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // =================================
                                // ลูกค้า
                                // =================================
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.deepOrange.shade50,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.deepOrange,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ลูกค้า',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),

                                          Text(
                                            o.customerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),

                                // =================================
                                // รายการอาหาร
                                // =================================
                                ...o.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),

                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: Colors.deepOrange,
                                              ),

                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Text(
                                          'x${item.qty}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // =================================
                                // หมายเหตุ
                                // =================================
                                if (o.note.isNotEmpty) ...[
                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.all(8),

                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.amber.shade200,
                                      ),
                                    ),

                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.sticky_note_2,
                                          size: 16,
                                          color: Colors.amber[800],
                                        ),

                                        const SizedBox(width: 6),

                                        Expanded(
                                          child: Text(
                                            'หมายเหตุ: ${o.note}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.amber[900],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),

                                // =================================
                                // ราคา + ปุ่มสถานะ
                                // =================================
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ยอดรวม',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey.shade500,
                                            ),
                                          ),
                                          Text(
                                            '฿${o.total}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.deepOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _OrderStatusBadge(status: o.status),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (o.status == OrderStatus.pending) {
                                        db.acceptOrder(o.id);
                                      } else {
                                        db.advanceStatus(o.id, o.status);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      OrderStatus.actionLabel(o.status) ??
                                          'ถัดไป',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}

// =========================================================
// ปุ่มเมนูของร้าน
// =========================================================

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (status) {
      OrderStatus.pending => const Color(0xFFFFF1E6),
      OrderStatus.accepted => const Color(0xFFE8F2FF),
      OrderStatus.cooking => const Color(0xFFE5F7FA),
      OrderStatus.ready => const Color(0xFFE8F6EC),
      _ => const Color(0xFFF0F2F4),
    };
    final foregroundColor = switch (status) {
      OrderStatus.pending => const Color(0xFFC84A0C),
      OrderStatus.accepted => const Color(0xFF2167B2),
      OrderStatus.cooking => const Color(0xFF087E8B),
      OrderStatus.ready => const Color(0xFF268044),
      _ => Colors.blueGrey,
    };
    final icon = switch (status) {
      OrderStatus.pending => Icons.schedule_rounded,
      OrderStatus.accepted => Icons.thumb_up_alt_rounded,
      OrderStatus.cooking => Icons.soup_kitchen_rounded,
      OrderStatus.ready => Icons.check_circle_rounded,
      _ => Icons.receipt_long_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            OrderStatus.labels[status] ?? 'สถานะออเดอร์',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
