class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authors,
    this.year,
    this.coverUrl,
    this.subjects = const [],
    this.description,
    this.source = 'Open Library',
  });

  final String id;
  final String title;
  final List<String> authors;
  final int? year;
  final String? coverUrl;
  final List<String> subjects;
  final String? description;

  /// '카카오 책 검색', 'Open Library', 'Google Books'
  final String source;

  String get authorText => authors.isEmpty ? '작가 미상' : authors.join(', ');

  Book copyWith({String? description}) => Book(
        id: id,
        title: title,
        authors: authors,
        year: year,
        coverUrl: coverUrl,
        subjects: subjects,
        description: description ?? this.description,
        source: source,
      );
}

enum BookSort {
  relevance('관련도순'),
  newest('최신순');

  const BookSort(this.label);
  final String label;
}
