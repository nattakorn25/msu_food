import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../services/db.dart';

class ProfileScreen extends StatelessWidget {
  final String shopId;

  const ProfileScreen({
    super.key,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    final Db db = Db();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'โปรไฟล์ลูกค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =====================================================
      // รายชื่อลูกค้า
      // =====================================================

      body: StreamBuilder<List<FoodOrder>>(
        stream: db.watchShopOrders(shopId),

        builder: (context, snapshot) {
          // กำลังโหลด
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // เกิด Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'เกิดข้อผิดพลาด\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          // =================================================
          // สร้างรายชื่อลูกค้าไม่ให้ซ้ำ
          // =================================================

          final Map<String, List<FoodOrder>> customerOrders = {};

          for (final order in orders) {
            final customerId = order.customerId;

            if (customerId.isEmpty) {
              continue;
            }

            customerOrders.putIfAbsent(
              customerId,
              () => [],
            );

            customerOrders[customerId]!.add(order);
          }

          // ไม่มีลูกค้า
          if (customerOrders.isEmpty) {
            return _emptyCustomer();
          }

          // =================================================
          // เรียงลูกค้าที่สั่งล่าสุดขึ้นก่อน
          // =================================================

          final customers =
              customerOrders.entries.toList();

          customers.sort(
            (a, b) {
              final ordersA = a.value;
              final ordersB = b.value;

              final dateA =
                  _getLatestDate(ordersA);

              final dateB =
                  _getLatestDate(ordersB);

              return dateB.compareTo(dateA);
            },
          );

          // =================================================
          // แสดงจำนวนลูกค้า
          // =================================================

          return Column(
            children: [
              // ส่วนหัวจำนวนลูกค้า
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        color:
                            Colors.deepOrange.shade50,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.people,
                        color: Colors.deepOrange,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ลูกค้าของร้าน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${customers.length} คน',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =================================================
              // รายชื่อลูกค้า
              // =================================================

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),

                  itemCount: customers.length,

                  itemBuilder: (context, index) {
                    final customerId =
                        customers[index].key;

                    final orders =
                        customers[index].value;

                    return _customerCard(
                      context,
                      customerId,
                      orders,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // การ์ดลูกค้า
  // ==========================================================

  Widget _customerCard(
    BuildContext context,
    String customerId,
    List<FoodOrder> orders,
  ) {
    final latestOrder =
        _getLatestOrder(orders);

    String customerName =
        latestOrder.customerName.trim();

    if (customerName.isEmpty) {
      customerName = 'ลูกค้า';
    }

    final latestDate =
        latestOrder.createdAt;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 8,
        ),

        // =====================================================
        // รูปลูกค้า
        // =====================================================

        leading: CircleAvatar(
          radius: 25,

          backgroundColor:
              Colors.deepOrange.shade100,

          child: const Icon(
            Icons.person,
            color: Colors.deepOrange,
            size: 28,
          ),
        ),

        // =====================================================
        // ชื่อลูกค้า
        // =====================================================

        title: Text(
          customerName,

          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        // =====================================================
        // จำนวนครั้งที่สั่ง
        // =====================================================

        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 4),

            Text(
              'สั่งอาหาร ${orders.length} ครั้ง',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            if (latestDate != null) ...[
              const SizedBox(height: 2),

              Text(
                'สั่งล่าสุด ${_formatDate(latestDate)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),

        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),

        // =====================================================
        // กดดูประวัติการสั่งซื้อของลูกค้าคนนั้น
        // =====================================================

        onTap: () {
          _showCustomerOrders(
            context,
            customerName,
            orders,
          );
        },
      ),
    );
  }

  // ==========================================================
  // แสดงรายการที่ลูกค้าคนนั้นเคยสั่ง
  // ==========================================================

  void _showCustomerOrders(
    BuildContext context,
    String customerName,
    List<FoodOrder> orders,
  ) {
    final sortedOrders =
        List<FoodOrder>.from(orders);

    sortedOrders.sort(
      (a, b) {
        return _getDate(b).compareTo(
          _getDate(a),
        );
      },
    );

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
                  0.75,

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),

          child: Column(
            children: [
              // =================================================
              // หัวข้อ
              // =================================================

              Padding(
                padding: const EdgeInsets.all(16),

                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Colors.deepOrange.shade100,

                      child: const Icon(
                        Icons.person,
                        color:
                            Colors.deepOrange,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        customerName,

                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.close,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
              ),

              // =================================================
              // รายการสั่งซื้อ
              // =================================================

              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.all(12),

                  itemCount:
                      sortedOrders.length,

                  itemBuilder:
                      (context, index) {
                    final order =
                        sortedOrders[index];

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .receipt_long,
                                  color:
                                      Colors.deepOrange,
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Expanded(
                                  child: Text(
                                    _formatDate(
                                      _getDate(
                                        order,
                                      ),
                                    ),

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),

                                _statusBadge(
                                  order.status,
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            ...order.items.map(
                              (item) {
                                return Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 3,
                                  ),

                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                        ),
                                      ),

                                      Text(
                                        'x${item.qty}',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const Divider(),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [
                                const Text(
                                  'ยอดรวม',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                Text(
                                  '${order.total.toStringAsFixed(2)} บาท',

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.deepOrange,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  // ==========================================================
  // ลูกค้าที่ไม่มีข้อมูล
  // ==========================================================

  Widget _emptyCustomer() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 15),

          Text(
            'ยังไม่มีลูกค้าที่เคยสั่งซื้อ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // หาวันที่สั่งล่าสุด
  // ==========================================================

  DateTime _getLatestDate(
    List<FoodOrder> orders,
  ) {
    DateTime latest =
        DateTime(2000);

    for (final order in orders) {
      final date =
          order.createdAt ??
              DateTime(2000);

      if (date.isAfter(latest)) {
        latest = date;
      }
    }

    return latest;
  }

  // ==========================================================
  // หาออเดอร์ล่าสุด
  // ==========================================================

  FoodOrder _getLatestOrder(
    List<FoodOrder> orders,
  ) {
    FoodOrder latest = orders.first;

    for (final order in orders) {
      if (_getDate(order)
          .isAfter(_getDate(latest))) {
        latest = order;
      }
    }

    return latest;
  }

  // ==========================================================
  // วันที่ของออเดอร์
  // ==========================================================

  DateTime _getDate(FoodOrder order) {
    return order.createdAt ??
        DateTime(2000);
  }

  // ==========================================================
  // แสดงวันที่
  // ==========================================================

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year + 543;

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year '
        '$hour:$minute น.';
  }

  // ==========================================================
  // สถานะ
  // ==========================================================

  Widget _statusBadge(String status) {
    String text;

    switch (status) {
      case OrderStatus.pending:
        text = 'รอรับออเดอร์';
        break;

      case OrderStatus.accepted:
        text = 'รับออเดอร์แล้ว';
        break;

      case OrderStatus.cooking:
        text = 'กำลังปรุงอาหาร';
        break;

      case OrderStatus.ready:
        text = 'อาหารพร้อมแล้ว';
        break;

      case OrderStatus.completed:
        text = 'เสร็จสิ้น';
        break;

      case OrderStatus.cancelled:
        text = 'ยกเลิกแล้ว';
        break;

      default:
        text = 'ไม่ทราบสถานะ';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}