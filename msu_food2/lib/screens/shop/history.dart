import 'package:flutter/material.dart';

import '../../models/food_order.dart';
import '../../services/db.dart';
import '../../widgets/menu_image.dart';

const _historyCream = Color(0xFFFFFDF7);
const _historyInk = Color(0xFF2D3142);
const _historyTeal = Color(0xFF5D9C91);
const _historyPeach = Color(0xFFFFF0E4);
const _historyLine = Color(0xFFECE9E1);

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
      backgroundColor: _historyCream,
      appBar: AppBar(
        backgroundColor: _historyCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _historyInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ประวัติออเดอร์',
          style: TextStyle(
            color: _historyInk,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0E9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _historyLine),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'ช่วงก่อนหน้า',
                  style: IconButton.styleFrom(
                    backgroundColor: _historyPeach,
                    foregroundColor: _historyInk,
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _historyLine),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: _historyTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                            style: const TextStyle(
                              color: _historyInk,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'ช่วงถัดไป',
                  style: IconButton.styleFrom(
                    backgroundColor: _historyPeach,
                    foregroundColor: _historyInk,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
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
                    child: CircularProgressIndicator(color: _historyTeal),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'โหลดประวัติออเดอร์ไม่สำเร็จ\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _historyInk),
                      ),
                    ),
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
                                    color: _historyTeal,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ไม่มีประวัติออเดอร์ในวันที่เลือก',
                                    style: TextStyle(
                                      color: _historyInk,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          top: BorderSide(color: _historyLine),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _historyInk.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, -3),
                          ),
                        ],
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
                                  color: _historyInk,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'สำเร็จ $completedOrders ออเดอร์',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _historyInk,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ยอดรับจากออเดอร์สำเร็จ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _historyInk.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalRevenue บาท',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _historyTeal,
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
            color: isSelected ? const Color(0xFFDDEFEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(color: const Color(0xFFB8DCD3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 14, color: _historyTeal),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? _historyInk
                      : _historyInk.withValues(alpha: 0.65),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _historyLine),
        boxShadow: [
          BoxShadow(
            color: _historyInk.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: _historyInk,
                ),
              ),
              Text(
                '${order.total} บาท',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _historyTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            order.createdAt != null
                ? "${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year} ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}"
                : '',
            style: TextStyle(
              fontSize: 12,
              color: _historyInk.withValues(alpha: 0.58),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _historyPeach,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 11,
                color: _historyInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: _historyLine),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: order.items.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    MenuImage(bytes: item.imageBytes, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.name} x${item.qty}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _historyInk,
                        ),
                      ),
                    ),
                    Text(
                      '${item.subtotal} บาท',
                      style: const TextStyle(fontSize: 13, color: _historyInk),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
