class EpubBook {
  final String title;
  final String author;
  final String identifier;
  final List<EpubChapter> chapters;
  final Map<String, String> resources;
  final String? coverImage;

  EpubBook({
    required this.title,
    required this.author,
    required this.identifier,
    required this.chapters,
    required this.resources,
    this.coverImage,
  });
}

class EpubChapter {
  final String id;
  final String title;
  final String content;
  final String href;
  final int order;
  final List<EpubChapter> subChapters;

  EpubChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.href,
    required this.order,
    this.subChapters = const [],
  });
}

class ReadingPosition {
  final int chapterIndex;
  final double scrollOffset;
  final DateTime timestamp;

  ReadingPosition({
    required this.chapterIndex,
    required this.scrollOffset,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'chapterIndex': chapterIndex,
    'scrollOffset': scrollOffset,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ReadingPosition.fromJson(Map<String, dynamic> json) =>
      ReadingPosition(
        chapterIndex: json['chapterIndex'],
        scrollOffset: json['scrollOffset'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );
}

class Bookmark {
  final String id;
  final String bookId;
  final int chapterIndex;
  final double scrollOffset;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.scrollOffset,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookId': bookId,
    'chapterIndex': chapterIndex,
    'scrollOffset': scrollOffset,
    'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'],
    bookId: json['bookId'],
    chapterIndex: json['chapterIndex'],
    scrollOffset: json['scrollOffset'],
    note: json['note'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
  );
}
