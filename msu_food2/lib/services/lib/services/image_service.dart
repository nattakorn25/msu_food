import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageService {
  // กตกาิ ขนาดสงู สดุ ของรปู หลงัยอ่ 200 KB
  static const int maxBytes = 200 * 1024;
  final ImagePicker _picker = ImagePicker();

  /// เปิดกลอง้ หรอื คลงัภาพ แลว้คนื รปู เป็นขอความ ้ Base64
  /// คนื null เมอื่ ผใชู้ กด้ ยกเลกิ
  /// โยน Exception เมอื่ รปู ใหญเก่ นิ กตกาิ
  Future<String?> pickAsBase64(ImageSource source) async {
    final XFile? x = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 60,
    );
    if (x == null) return null;
    final Uint8List bytes = await x.readAsBytes();
    if (bytes.length > maxBytes) {
      throw Exception(
        'รปู มขนาด ี ${bytes.length ~/ 1024} KB เกนิ 200 KB '
        'กรณา ุ เลอกื รปู อนื่ ',
      );
    }
    return base64Encode(bytes);
  }

  /// แปลงขอความ ้ Base64 กลบั เป็นไบตส์ ำ หรับแสดงผล
  /// ถา้ไมม่ รีปู หรอื ขอม้ ลู เสยี จะคนื null แทนการทำ ใหแอ้ ปพัง
  static Uint8List? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      return base64Decode(text);
    } catch (_) {
      return null;
    }
  }
}
