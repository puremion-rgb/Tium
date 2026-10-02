import 'package:flutter/material.dart';

import '../../models/book.dart';

/// 표지 이미지. 없거나 못 불러오면 제목으로 만든 표지를 보여 준다.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.width = 56, this.height = 78});

  final Book book;
  final double width;
  final double height;

  static const _palette = [
    (Color(0xFFF2C14E), Color(0xFF3B4A5A)),
    (Color(0xFF2F5D8C), Color(0xFFF4D35E)),
    (Color(0xFF33415C), Color(0xFFE9C46A)),
    (Color(0xFFE9E2CF), Color(0xFF2F5D8C)),
    (Color(0xFF7FB069), Color(0xFFFFFFFF)),
  ];

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: '${book.title} 표지',
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) => progress == null ? child : _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    final (bg, fg) = _palette[book.title.hashCode.abs() % _palette.length];
    return Container(
      color: bg,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.bottomLeft,
      child: Text(
        book.title,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: width / 7, height: 1.2),
      ),
    );
  }
}
