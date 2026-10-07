import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item.dart';
import '../../services/db.dart';
import '../../services/image_service.dart';
import '../../widgets/menu_image.dart';

const _menuCream = Color(0xFFFFFDF7);
const _menuInk = Color(0xFF2D3142);
const _menuTeal = Color(0xFF5D9C91);
const _menuPeach = Color(0xFFFFF0E4);
const _menuLine = Color(0xFFECE9E1);

class MenuManageScreen extends StatefulWidget {
  final String shopId;

  const MenuManageScreen({super.key, required this.shopId});

  @override
  State<MenuManageScreen> createState() => _MenuManageScreenState();
}

class _MenuManageScreenState extends State<MenuManageScreen> {
  final db = Db();

  // ฟังก์ชันแสดง Popup Form สำหรับเพิ่ม/แก้ไขเมนูพร้อมรูปภาพ
  Future<void> _openForm(BuildContext context, Db db, MenuItem? item) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );
    final formKey = GlobalKey<FormState>();
    final imageService = ImageService();

    // สถานะของรูปภาพภายในฟอร์ม
    String? newImage; // Base64 ของรูปที่เพิ่งเลือก
    bool removeImage = false; // ผู้ใช้กดลบรูปเดิม
    bool saving = false; // กำลังบันทึก ใช้กันกดซ้ำ

    try {
      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            // ลำดับการเลือกรูปตัวอย่าง: รูปใหม่ > รูปเดิม > ไม่มีรูป
            final preview = newImage != null
                ? ImageService.decode(newImage!)
                : (removeImage ? null : item?.imageBytes);

            Future<void> pick(ImageSource source) async {
              try {
                final b64 = await imageService.pickAsBase64(source);
                if (b64 == null || !ctx.mounted) return; // ยกเลิก
                setDialogState(() {
                  newImage = b64;
                  removeImage = false;
                });
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: _menuCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(item == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _menuLine),
                        ),
                        child: MenuImage(bytes: preview, size: 144),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เพิ่มรูปจากกล้องหรือคลังภาพ',
                        style: TextStyle(
                          color: _menuInk.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'ถ่ายรูป',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE5F1EC),
                              foregroundColor: _menuTeal,
                            ),
                            icon: const Icon(Icons.photo_camera_rounded),
                            onPressed: saving
                                ? null
                                : () => pick(ImageSource.camera),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'เลือกจากคลังภาพ',
                            style: IconButton.styleFrom(
                              backgroundColor: _menuPeach,
                              foregroundColor: _menuInk,
                            ),
                            icon: const Icon(Icons.photo_library_rounded),
                            onPressed: saving
                                ? null
                                : () => pick(ImageSource.gallery),
                          ),
                          if (preview != null)
                            IconButton.filledTonal(
                              tooltip: 'ลบรูป',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFBE9E7),
                                foregroundColor: Colors.red.shade700,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: saving
                                  ? null
                                  : () => setDialogState(() {
                                      newImage = null;
                                      removeImage = true;
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        maxLength: 60,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อเมนู',
                          prefixIcon: Icon(Icons.restaurant_menu_rounded),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกชื่อเมนู';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'ราคา (บาท)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (value) {
                          final price = num.tryParse(value?.trim() ?? '');
                          if (price == null || price < 0) {
                            return 'กรุณากรอกราคาที่ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _menuTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final name = nameCtrl.text.trim();
                          final price = num.parse(priceCtrl.text.trim());

                          setDialogState(() => saving = true);
                          try {
                            if (item == null) {
                              await db.addMenuItem(
                                widget.shopId,
                                name,
                                price,
                                imageBase64: newImage,
                              );
                            } else {
                              await db.updateMenuItem(
                                item.id,
                                name,
                                price,
                                imageBase64: newImage,
                                removeImage: removeImage,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      nameCtrl.dispose();
      priceCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _menuCream,
      appBar: AppBar(
        backgroundColor: _menuCream,
        foregroundColor: _menuInk,
        scrolledUnderElevation: 0,
        title: const Text(
          'จัดการเมนูอาหาร',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: db.watchMenu(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'โหลดรายการเมนูไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _menuInk),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _menuPeach,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: _menuTeal,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีเมนูอาหาร',
                      style: TextStyle(
                        color: _menuInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'แตะปุ่ม + เพื่อเพิ่มเมนูแรกของร้าน',
                      style: TextStyle(color: _menuInk.withValues(alpha: 0.62)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: _menuLine),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  leading: MenuImage(
                    bytes: item.imageBytes,
                    size: 58,
                    grayscale: !item.available,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: _menuInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item.available
                        ? '${item.price} บาท'
                        : 'ปิดขาย · ${item.price} บาท',
                    style: TextStyle(
                      color: item.available
                          ? _menuInk.withValues(alpha: 0.62)
                          : Colors.blueGrey,
                    ),
                  ),
                  onTap: () => _openForm(context, db, item),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.available,
                        activeTrackColor: const Color(0xFFDDEFEA),
                        activeThumbColor: _menuTeal,
                        onChanged: (available) async {
                          try {
                            await db.setAvailable(item.id, available);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เปลี่ยนสถานะเมนูไม่สำเร็จ: $e'),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'ลบเมนู ${item.name}',
                        style: IconButton.styleFrom(
                          foregroundColor: _menuInk.withValues(alpha: 0.65),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: _menuCream,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: const Text('ลบเมนูนี้?'),
                              content: Text('ต้องการลบ “${item.name}” หรือไม่'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red.shade400,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('ลบเมนู'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          try {
                            await db.deleteMenuItem(item.id);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ลบเมนูไม่สำเร็จ: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, db, null),
        backgroundColor: _menuTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
