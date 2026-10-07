import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../services/db.dart';

class HistoryScreen extends StatefulWidget {
  final String shopId;

  const HistoryScreen({super.key, required this.shopId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int selectedPeriodIndex = 0; // 0: รายวัน, 1: รายสัปดาห์, 2: รายเดือน
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ประวัติออเดอร์',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 1. Segmented Control Switcher (รายวัน / รายสัปดาห์ / รายเดือน)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFB0BEC5), width: 0.8),
              ),
              child: Row(
                children: [
                  _buildSegmentItem(0, 'รายวัน'),
                  _buildSegmentItem(1, 'รายสัปดาห์'),
                  _buildSegmentItem(2, 'รายเดือน'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Date Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black54),
                  onPressed: () => _movePeriod(-1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00897B),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: Color(0xFF00897B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                            style: const TextStyle(
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black54),
                  onPressed: () => _movePeriod(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. ดึงออเดอร์จาก Firebase Realtime / Firestore ผ่าน StreamBuilder
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: db.watchShopHistory(widget.shopId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }

                final allOrders = snapshot.data ?? [];

                final periodStart = _periodStart;
                final periodEnd = _periodEnd;

                final filteredOrders = allOrders.where((order) {
                  final orderDate = order.createdAt;
                  if (orderDate == null) return false;
                  return !orderDate.isBefore(periodStart) &&
                      orderDate.isBefore(periodEnd);
                }).toList();

                // คำนวณยอดสรุป
                final totalOrders = filteredOrders.length;
                final completedOrders = filteredOrders
                    .where((o) => o.status == OrderStatus.completed)
                    .length;
                final totalRevenue = filteredOrders
                    .where((o) => o.status == OrderStatus.completed)
                    .fold<num>(0, (sum, o) => sum + o.total);

                return Column(
                  children: [
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ไม่มีประวัติออเดอร์ในวันที่เลือก',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                    ),

                    // 4. Bottom Summary Bar (สรุปยอดรวมจากข้อมูลจริง)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4F3),
                        border: Border(
                          top: BorderSide(color: Color(0xFFCFD8DC), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'รวม $totalOrders ออเดอร์',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'สำเร็จ $completedOrders ออเดอร์',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'ยอดรับจากออเดอร์สำเร็จ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalRevenue บาท',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime get _periodStart {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    if (selectedPeriodIndex == 1) {
      return date.subtract(Duration(days: date.weekday - DateTime.monday));
    }
    if (selectedPeriodIndex == 2) {
      return DateTime(date.year, date.month);
    }
    return date;
  }

  DateTime get _periodEnd {
    if (selectedPeriodIndex == 1) {
      return _periodStart.add(const Duration(days: 7));
    }
    if (selectedPeriodIndex == 2) {
      return DateTime(_periodStart.year, _periodStart.month + 1);
    }
    return _periodStart.add(const Duration(days: 1));
  }

  void _movePeriod(int direction) {
    setState(() {
      if (selectedPeriodIndex == 1) {
        selectedDate = selectedDate.add(Duration(days: direction * 7));
      } else if (selectedPeriodIndex == 2) {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month + direction,
        );
      } else {
        selectedDate = selectedDate.add(Duration(days: direction));
      }
    });
  }

  // Widget ปุ่มเลือกช่วงเวลา
  Widget _buildSegmentItem(int index, String title) {
    final isSelected = selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriodIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB2DFDB) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: const Color(0xFF80CBC4), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: Color(0xFF004D40)),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF004D40) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget แสดง Card รายการออเดอร์จริง
  Widget _buildOrderCard(FoodOrder order) {
    final statusLabel = OrderStatus.labels[order.status] ?? order.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${order.total} บาท',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            order.createdAt != null
                ? "${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year} ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}"
                : '',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'สถานะ: $statusLabel',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: Color(0xFFE0E0E0)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: order.items.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  '${item.name} x${item.qty} ${item.price} บาท',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
