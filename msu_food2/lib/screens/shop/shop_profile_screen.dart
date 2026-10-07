import 'package:flutter/material.dart';

import '../../models/shop.dart';
import '../../services/db.dart';

const _profileCream = Color(0xFFFFFDF7);
const _profileInk = Color(0xFF2D3142);
const _profileTeal = Color(0xFF5D9C91);
const _profilePeach = Color(0xFFFFF0E4);

class ShopProfileScreen extends StatelessWidget {
  final String shopId;

  const ShopProfileScreen({
    super.key,
    required this.shopId,
  });

  static const teamMembers = [
    {'id': '66010914166', 'name': 'นางสาวณัทกร เพียรจิต'},
    {'id': '66010914102', 'name': 'นายชัชวาล วุฑฒะกุล'},
    {'id': '66010914107', 'name': 'นายปฏิภาณ พงษ์เพ็ชร'},
    {'id': '660109098', 'name': 'นายเศรษฐพงษ์ คำเสนาะ'},
  ];

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return Scaffold(
      backgroundColor: _profileCream,
      appBar: AppBar(
        backgroundColor: _profileCream,
        foregroundColor: _profileInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'โปรไฟล์ร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<Shop>(
        stream: db.watchShop(shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: _profileTeal,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'โหลดข้อมูลร้านค้าไม่สำเร็จ',
                      style: TextStyle(
                        color: _profileInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _profileInk.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _profileTeal),
            );
          }

          final shop = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5F1EC), Color(0xFFFFF0E4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFECE9E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: _profileTeal,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              color: _profileInk,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: shop.isOpen
                                  ? const Color(0xFFDDEFEA)
                                  : _profilePeach,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              shop.isOpen ? 'เปิดรับออเดอร์' : 'ปิดให้บริการ',
                              style: const TextStyle(
                                color: _profileInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: _profileTeal,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ทีมงานของเรา',
                      style: TextStyle(
                        color: _profileInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _profilePeach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${teamMembers.length} คน',
                      style: const TextStyle(
                        color: _profileInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0; index < teamMembers.length; index++) ...[
                      if (index > 0)
                        const Divider(
                          height: 1,
                          indent: 76,
                          endIndent: 16,
                          color: Color(0xFFECE9E1),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _profilePeach,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: _profileTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          teamMembers[index]['name']!,
                          style: const TextStyle(
                            color: _profileInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'รหัสประจำตัว: ${teamMembers[index]['id']}',
                          style: TextStyle(
                            color: _profileInk.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}