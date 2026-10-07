import 'dart:typed_data';

import 'package:flutter/material.dart';

class MenuImage extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  final bool grayscale;

  const MenuImage({
    super.key,
    required this.bytes,
    this.size = 56,
    this.grayscale = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = bytes == null
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
            gaplessPlayback: true,
            cacheWidth: (size * 3).round(),
          );
    final displayedImage = grayscale && bytes != null
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: image,
          )
        : image;

    return Semantics(
      button: bytes != null,
      label: bytes == null ? 'ไม่มีรูปอาหาร' : 'แตะเพื่อดูรูปขนาดใหญ่',
      child: GestureDetector(
        onTap: bytes == null
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        minScale: 0.7,
                        maxScale: 4,
                        child: SizedBox(
                          width: 360,
                          height: 360,
                          child: Center(
                            child: ColorFiltered(
                              colorFilter: grayscale
                                  ? const ColorFilter.matrix([
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ])
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.srcOver,
                                    ),
                              child: Image.memory(
                                bytes!,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          tooltip: 'ปิดรูป',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: size,
            height: size,
            child: displayedImage,
          ),
        ),
      ),
    );
  }
}
