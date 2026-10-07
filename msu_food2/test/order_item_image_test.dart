import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:msu_food2/models/food_order.dart';
import 'package:msu_food2/services/image_service.dart';

void main() {
  test('order item image survives Firestore map serialization', () {
    final imageBytes = Uint8List.fromList([0, 1, 2, 255]);
    final item = OrderItem(
      name: 'Pizza',
      price: 199,
      qty: 2,
      imageBytes: imageBytes,
    );

    final encoded = item.toMap();
    final decoded = OrderItem.fromMap(encoded);

    expect(encoded['imageBase64'], base64Encode(imageBytes));
    expect(decoded.imageBytes, orderedEquals(imageBytes));
    expect(decoded.subtotal, 398);
  });

  test('older order items without a photo remain readable', () {
    final item = OrderItem.fromMap({
      'name': 'Salad',
      'price': 89,
      'qty': 1,
    });

    expect(item.name, 'Salad');
    expect(item.imageBytes, isNull);
  });

  test('invalid photo data does not prevent reading an order item', () {
    final item = OrderItem.fromMap({
      'name': 'Soup',
      'price': 99,
      'qty': 1,
      'imageBase64': 'not-base64!',
    });

    expect(item.imageBytes, isNull);
    expect(ImageService.decode(null), isNull);
  });
}
