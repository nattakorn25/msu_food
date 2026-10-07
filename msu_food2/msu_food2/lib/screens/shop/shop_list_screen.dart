import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/db.dart';
import '../customer/menu_screen.dart';

class ShopListScreen extends StatefulWidget {
  final User user;

  const ShopListScreen({super.key, required this.user});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _openOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F2),
      appBar: AppBar(
        title: const Text('เลือกร้านอาหาร'),
        backgroundColor: const Color(0xFFF4F6F2),
        foregroundColor: const Color(0xFF25362D),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF31443B)),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF183D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'มื้อนี้กินอะไรดี?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'เลือกร้านโปรด แล้วเลือกเมนูได้เลย',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF27A45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.ramen_dining_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาร้านอาหาร',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'ล้างคำค้นหา',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ทุกร้าน'),
                      selected: !_openOnly,
                      onSelected: (_) => setState(() => _openOnly = false),
                      selectedColor: const Color(0xFFFFE8DA),
                      labelStyle: TextStyle(
                        color: !_openOnly
                            ? const Color(0xFFB94E1E)
                            : const Color(0xFF56645C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('เปิดรับออเดอร์'),
                      selected: _openOnly,
                      onSelected: (_) => setState(() => _openOnly = true),
                      selectedColor: const Color(0xFFDDF2E3),
                      labelStyle: TextStyle(
                        color: _openOnly
                            ? const Color(0xFF267548)
                            : const Color(0xFF56645C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Shop>>(
              stream: db.watchShops(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ShopListMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'โหลดรายการร้านไม่สำเร็จ',
                    detail: '${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ShopListMessage(
                    loading: true,
                    title: 'กำลังโหลดร้านค้า...',
                  );
                }

                final shops = snapshot.data ?? <Shop>[];
                final query = _searchQuery.trim().toLowerCase();
                final filteredShops = shops.where((shop) {
                  final matchesQuery =
                      query.isEmpty || shop.name.toLowerCase().contains(query);
                  return matchesQuery && (!_openOnly || shop.isOpen);
                }).toList();

                if (filteredShops.isEmpty) {
                  return _ShopListMessage(
                    icon: Icons.storefront_outlined,
                    title: shops.isEmpty
                        ? 'ยังไม่มีร้านค้าในระบบ'
                        : 'ไม่พบร้านที่ตรงกับตัวกรอง',
                    detail: shops.isEmpty
                        ? 'ร้านค้าที่เปิดให้บริการจะแสดงที่นี่'
                        : 'ลองเปลี่ยนคำค้นหาหรือเลือกดูทุกร้าน',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filteredShops.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final openCount = shops
                          .where((shop) => shop.isOpen)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '$openCount ร้านกำลังเปิด · ${filteredShops.length} ร้านที่แสดง',
                          style: const TextStyle(
                            color: Color(0xFF66736B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    final shop = filteredShops[index - 1];
                    return _ShopTile(
                      shop: shop,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MenuScreen(shop: shop, user: widget.user),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;

  const _ShopTile({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = shop.isOpen
        ? const Color(0xFF267548)
        : const Color(0xFF707B74);
    final statusBackground = shop.isOpen
        ? const Color(0xFFE5F4E9)
        : const Color(0xFFECEFED);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8DA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFD85D2A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF25362D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            shop.isOpen
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_filled_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            shop.isOpen ? 'เปิดรับออเดอร์' : 'ปิดให้บริการ',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF91A097),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopListMessage extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? detail;
  final bool loading;

  const _ShopListMessage({
    this.icon,
    required this.title,
    this.detail,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: Color(0xFFD85D2A))
            else
              Icon(icon, color: const Color(0xFF718078), size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF25362D),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF718078), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
