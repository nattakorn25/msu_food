import 'package:flutter/material.dart';

import '../../models/shop.dart';
import '../../services/db.dart';

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
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'โปรไฟล์ร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<Shop>(
        stream: db.watchShop(shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('ไม่สามารถโหลดข้อมูลร้านค้าได้'));
          }

          final shopName = snapshot.data?.name ?? 'กำลังโหลด...';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'ชื่อร้านค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange.shade50,
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.deepOrange,
                    ),
                  ),
                  title: Text(
                    shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'รายชื่อสมาชิก (4 คน)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0; index < teamMembers.length; index++) ...[
                      if (index > 0) const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepOrange.shade50,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          teamMembers[index]['name']!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'รหัสประจำตัว: ${teamMembers[index]['id']}',
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