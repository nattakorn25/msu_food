import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/db.dart';
import 'shop/shop_list_screen.dart';
import 'shop/order_board_screen.dart';

class RoleGate extends StatelessWidget {
  final User user;

  const RoleGate({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return FutureBuilder<String?>(
      future: db.getUserRole(user.uid),
      builder: (context, roleSnapshot) {
        // 1. กำลังโหลดข้อมูล
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            ),
          );
        }

        // 2. เกิด Error
        if (roleSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${roleSnapshot.error}',
              ),
            ),
          );
        }

        // 3. ดึงค่า Role มาเก็บในตัวแปรก่อน (ต้องอยู่หลัง โหลดเสร็จแล้ว)
        final role = roleSnapshot.data;

        debugPrint('USER UID   : ${user.uid}');
        debugPrint('USER ROLE  : $role');

        // 4. เช็ก Role ฝั่ง CUSTOMER
        if (role == 'customer') {
         return ShopListScreen(user: user);
        }

        // 5. เช็ก Role ฝั่ง SHOP
        if (role == 'shop') {
          return FutureBuilder<String?>(
            future: db.getUserShopId(user.uid),
            builder: (context, shopSnapshot) {
              if (shopSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepOrange,
                    ),
                  ),
                );
              }

              if (shopSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'เกิดข้อผิดพลาด: ${shopSnapshot.error}',
                    ),
                  ),
                );
              }

              final shopId = shopSnapshot.data;

              debugPrint('SHOP ID    : $shopId');

              if (shopId == null || shopId.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'ไม่พบข้อมูลร้านค้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return OrderBoardScreen(
                user: user,
                shopId: shopId,
              );
            },
          );
        }

        // 6. กรณีไม่พบ Role ใดๆ
        return Scaffold(
          appBar: AppBar(
            title: const Text('ไม่พบประเภทผู้ใช้'),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Text(
              'Role ที่ได้รับ: ${role ?? "null"}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}