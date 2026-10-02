import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/book.dart';
import '../../viewmodels/book_view_models.dart';
import 'book_cover.dart';

/// 7. 도서 상세
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookDetailProvider(book));
    final b = detail.valueOrNull ?? book;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Center(child: BookCover(book: b, width: 128, height: 180)),
                  const SizedBox(height: 18),
                  Text(b.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    [b.authorText, if (b.year != null) '${b.year}년'].join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (b.subjects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in b.subjects.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(99)),
                            child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (detail.isLoading)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Text(
                      b.description ?? '이 책은 소개 글이 아직 없어요.',
                      style: const TextStyle(height: 1.7, color: Color(0xFF4C534A)),
                    ),
                  const SizedBox(height: 12),
                  Text('도서 정보: ${b.source}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: () => context.push(Routes.questNew, extra: b.title),
                child: const Text('이 책으로 퀘스트 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
