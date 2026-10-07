import 'dart:typed_data';
import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final Uint8List? bytes; // ไบตของ ์ รปู (null = ไมม่ รีปู )
  final double size; // ความกวาง้ และความสงู ของกรอบ
  const MenuImage({super.key, required this.bytes, this.size = 56});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // มมุ โคง้
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null
            ? Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.restaurant,
                  color: Colors.grey.shade500,
                  size: size * 0.5,
                ),
              )
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                // ไมให่ ร้ปู กะพรบิเมอื่ StreamBuilder สราง้ หนา้จอใหม่
                gaplessPlayback: true,
                // ถอดรหสั รปู ตามขนาดทแสดง ี่ จรงิ ประหยดั หน่วยความจำ
                cacheWidth: (size * 3).round(),
              ),
      ),
    );
  }
}
