import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/book.dart';

abstract interface class BookRepository {
  Future<List<Book>> search(String query, {BookSort sort = BookSort.relevance});

  /// 상세 화면용 설명을 채워서 돌려준다.
  Future<Book> detail(Book book);
}

/// 책 검색 키. 코드에 직접 쓰지 않고 실행할 때 넣는다.
///   flutter run --dart-define-from-file=env.json
/// env.json 예: {"KAKAO_REST_KEY": "카카오 REST API 키", "GOOGLE_BOOKS_KEY": ""}
const kakaoRestKey = String.fromEnvironment('KAKAO_REST_KEY');
const googleBooksKey = String.fromEnvironment('GOOGLE_BOOKS_KEY');

/// 한글 검색: 카카오 → Google Books(키가 있을 때) → Open Library
/// 영어 검색: Open Library → 카카오 → Google Books(키가 있을 때)
/// 앞 순서가 실패하거나(시간 초과 포함) 결과가 없으면 다음 순서로 넘어간다.
class ApiBookRepository implements BookRepository {
  ApiBookRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final _hangul = RegExp(r'[가-힣]');

  @override
  Future<List<Book>> search(String query, {BookSort sort = BookSort.relevance}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final kakao = ('카카오', _searchKakao, kakaoRestKey.isNotEmpty);
    final google = ('Google Books', _searchGoogleBooks, googleBooksKey.isNotEmpty);
    final openLibrary = ('Open Library', _searchOpenLibrary, true);
    final order = _hangul.hasMatch(q) ? [kakao, google, openLibrary] : [openLibrary, kakao, google];

    Object? firstError;
    for (final (name, run, enabled) in order) {
      if (!enabled) continue;
      try {
        final books = await run(q, sort);
        if (books.isNotEmpty) return books;
        debugPrint('[BookRepository] $name: 결과 없음');
      } catch (e) {
        debugPrint('[BookRepository] $name 실패: $e');
        firstError ??= e;
      }
    }
    if (firstError != null) throw firstError;
    return const [];
  }

  /// 카카오(다음) 책 검색 https://developers.kakao.com/docs/latest/ko/daum-search/dev-guide#search-book
  Future<List<Book>> _searchKakao(String q, BookSort sort) async {
    final uri = Uri.https('dapi.kakao.com', '/v3/search/book', {
      'query': q,
      'size': '20',
      'sort': sort == BookSort.newest ? 'latest' : 'accuracy',
    });
    final json = await _getJson(uri, headers: {'Authorization': 'KakaoAK $kakaoRestKey'});
    final docs = (json['documents'] as List?) ?? const [];
    return docs.map((d) {
      final m = d as Map<String, dynamic>;
      final thumb = m['thumbnail'] as String? ?? '';
      final contents = (m['contents'] as String? ?? '').trim();
      return Book(
        id: (m['isbn'] as String? ?? '').split(' ').last,
        title: m['title'] as String? ?? '제목 없음',
        authors: ((m['authors'] as List?) ?? const []).cast<String>(),
        year: DateTime.tryParse(m['datetime'] as String? ?? '')?.year,
        coverUrl: thumb.isEmpty ? null : thumb,
        subjects: [if ((m['publisher'] as String? ?? '').isNotEmpty) m['publisher'] as String],
        description: contents.isEmpty ? null : contents,
        source: '카카오 책 검색',
      );
    }).toList();
  }

  Future<List<Book>> _searchOpenLibrary(String q, BookSort sort) async {
    final uri = Uri.https('openlibrary.org', '/search.json', {
      'q': q,
      'limit': '20',
      'fields': 'key,title,author_name,first_publish_year,cover_i,subject',
      if (sort == BookSort.newest) 'sort': 'new',
    });
    final json = await _getJson(uri);
    final docs = (json['docs'] as List?) ?? const [];
    return docs.map((d) {
      final m = d as Map<String, dynamic>;
      final cover = m['cover_i'];
      return Book(
        id: m['key'] as String? ?? '',
        title: m['title'] as String? ?? '제목 없음',
        authors: ((m['author_name'] as List?) ?? const []).cast<String>(),
        year: (m['first_publish_year'] as num?)?.toInt(),
        coverUrl: cover == null ? null : 'https://covers.openlibrary.org/b/id/$cover-M.jpg',
        subjects: ((m['subject'] as List?) ?? const []).cast<String>().take(3).toList(),
      );
    }).toList();
  }

  Future<List<Book>> _searchGoogleBooks(String q, BookSort sort) async {
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': q,
      'maxResults': '20',
      'langRestrict': 'ko',
      'orderBy': sort == BookSort.newest ? 'newest' : 'relevance',
      if (googleBooksKey.isNotEmpty) 'key': googleBooksKey,
    });
    final json = await _getJson(uri);
    final items = (json['items'] as List?) ?? const [];
    return items.map((it) {
      final m = it as Map<String, dynamic>;
      final info = m['volumeInfo'] as Map<String, dynamic>? ?? const {};
      final thumb = (info['imageLinks'] as Map<String, dynamic>?)?['thumbnail'] as String?;
      return Book(
        id: m['id'] as String? ?? '',
        title: info['title'] as String? ?? '제목 없음',
        authors: ((info['authors'] as List?) ?? const []).cast<String>(),
        year: int.tryParse((info['publishedDate'] as String? ?? '').split('-').first),
        coverUrl: thumb?.replaceFirst('http://', 'https://'),
        subjects: ((info['categories'] as List?) ?? const []).cast<String>(),
        description: info['description'] as String?,
        source: 'Google Books',
      );
    }).toList();
  }

  @override
  Future<Book> detail(Book book) async {
    if (book.description != null || book.source != 'Open Library' || book.id.isEmpty) return book;
    try {
      final json = await _getJson(Uri.parse('https://openlibrary.org${book.id}.json'));
      final d = json['description'];
      final text = d is String ? d : (d is Map ? d['value'] as String? : null);
      return book.copyWith(description: text);
    } catch (_) {
      return book; // 설명이 없어도 상세 화면은 보여 준다.
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {Map<String, String>? headers}) async {
    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw BookApiException(res.statusCode, uri.host);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

class FakeBookRepository implements BookRepository {
  const FakeBookRepository();

  static const _books = [
    Book(
      id: '/works/OL17930368W',
      title: '아주 작은 습관의 힘',
      authors: ['제임스 클리어'],
      year: 2019,
      subjects: ['자기계발', '습관', '성장'],
      description: '작은 습관이 쌓여 큰 변화를 만든다는 이야기를 다룬 책이에요. 1%씩 나아지는 방법과 좋은 습관을 오래 이어 가는 구조를 소개해요.',
    ),
    Book(id: 'fake-2', title: '마음의 기술', authors: ['예담 스미스'], year: 2021, subjects: ['심리']),
    Book(id: 'fake-3', title: '프랑켄슈타인', authors: ['메리 셸리'], year: 1818, subjects: ['고전', '소설']),
    Book(id: 'fake-4', title: '미움받을 용기', authors: ['기시미 이치로'], year: 2014, subjects: ['철학']),
  ];

  @override
  Future<List<Book>> search(String query, {BookSort sort = BookSort.relevance}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final q = query.trim();
    final list = q.isEmpty ? _books.toList() : _books.where((b) => b.title.contains(q) || b.authorText.contains(q)).toList();
    if (sort == BookSort.newest) list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    return list;
  }

  @override
  Future<Book> detail(Book book) async => book;
}

/// 도서 API가 200이 아닌 응답을 줬을 때
class BookApiException implements Exception {
  const BookApiException(this.statusCode, this.host);
  final int statusCode;
  final String host;

  @override
  String toString() => 'BookApiException($host, $statusCode)';
}
