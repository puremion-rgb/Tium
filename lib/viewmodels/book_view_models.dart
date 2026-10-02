import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/repositories/book_repository.dart';
import '../models/book.dart';

class BookSearchState {
  const BookSearchState({required this.query, required this.sort, required this.results});

  final String query;
  final BookSort sort;
  final List<Book> results;
}

/// 도서 검색 ViewModel. 처음에는 '습관' 관련 책을 보여 준다.
/// 카카오 키가 없으면 한글 검색이 거의 안 되므로 영어로 시작한다.
class BookSearchViewModel extends AutoDisposeAsyncNotifier<BookSearchState> {
  static const initialQuery = kakaoRestKey == '' ? 'atomic habits' : '습관';

  @override
  Future<BookSearchState> build() => _run(initialQuery, BookSort.relevance);

  Future<BookSearchState> _run(String query, BookSort sort) async {
    final results = await ref.read(bookRepositoryProvider).search(query, sort: sort);
    return BookSearchState(query: query, sort: sort, results: results);
  }

  Future<void> search(String query) async {
    final sort = state.valueOrNull?.sort ?? BookSort.relevance;
    state = const AsyncLoading<BookSearchState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _run(query, sort));
  }

  Future<void> setSort(BookSort sort) async {
    final query = state.valueOrNull?.query ?? initialQuery;
    state = const AsyncLoading<BookSearchState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _run(query, sort));
  }
}

final bookSearchViewModelProvider =
    AsyncNotifierProvider.autoDispose<BookSearchViewModel, BookSearchState>(BookSearchViewModel.new);

/// 상세 화면: 설명을 추가로 불러온다.
final bookDetailProvider = FutureProvider.autoDispose.family<Book, Book>(
  (ref, book) => ref.read(bookRepositoryProvider).detail(book),
);
