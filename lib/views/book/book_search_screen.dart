import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/book.dart';
import '../../viewmodels/book_view_models.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import 'book_cover.dart';

/// 6. 책에서 찾기 (한글: 카카오 · 영어: Open Library)
class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (v.trim().isNotEmpty) ref.read(bookSearchViewModelProvider.notifier).search(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(bookSearchViewModelProvider);
    final vm = ref.read(bookSearchViewModelProvider.notifier);
    final sort = search.valueOrNull?.sort ?? BookSort.relevance;

    return Scaffold(
      appBar: AppBar(title: const Text('책에서 찾기')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              onChanged: _onChanged,
              onSubmitted: (v) => vm.search(v),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '책 제목 또는 키워드를 입력하세요',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 12),
            ChoiceChipRow<BookSort>(items: BookSort.values, selected: sort, labelOf: (s) => s.label, onSelected: vm.setSort),
            const SizedBox(height: 12),
            if (search.isLoading && search.hasValue) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: search.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: StateView.loading,
                error: (e, _) => StateView.error(e, onRetry: () => vm.search(_query.text.isEmpty ? BookSearchViewModel.initialQuery : _query.text)),
                data: (s) => s.results.isEmpty
                    ? StateView(
                        illustration: const Icon(Icons.menu_book_outlined, size: 50, color: AppColors.primary),
                        title: '‘${s.query}’ 검색 결과가 없어요',
                        message: '다른 제목이나 작가 이름으로 찾아보세요',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemCount: s.results.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => i == s.results.length
                            ? Center(
                                child: Text('도서 정보: ${s.results.first.source}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              )
                            : _BookTile(book: s.results[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(Routes.bookDetail, extra: book),
      child: Row(
        children: [
          BookCover(book: book, width: 56, height: 78),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(book.authorText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  [if (book.year != null) '${book.year}년', if (book.subjects.isNotEmpty) book.subjects.first].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}
