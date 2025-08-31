import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/epub_book.dart';

class BookmarkService {
  static const String _bookmarksKey = 'epub_bookmarks';
  static const String _readingPositionsKey = 'reading_positions';

  // 书签管理
  static Future<List<Bookmark>> getBookmarks(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '{}';
    final bookmarksMap = jsonDecode(bookmarksJson) as Map<String, dynamic>;

    final bookBookmarks = bookmarksMap[bookId] as List<dynamic>? ?? [];
    return bookBookmarks.map((json) => Bookmark.fromJson(json)).toList();
  }

  static Future<void> addBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '{}';
    final bookmarksMap = jsonDecode(bookmarksJson) as Map<String, dynamic>;

    final bookBookmarks = bookmarksMap[bookmark.bookId] as List<dynamic>? ?? [];
    bookBookmarks.add(bookmark.toJson());
    bookmarksMap[bookmark.bookId] = bookBookmarks;

    await prefs.setString(_bookmarksKey, jsonEncode(bookmarksMap));
  }

  static Future<void> removeBookmark(String bookId, String bookmarkId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '{}';
    final bookmarksMap = jsonDecode(bookmarksJson) as Map<String, dynamic>;

    final bookBookmarks = bookmarksMap[bookId] as List<dynamic>? ?? [];
    bookBookmarks.removeWhere((json) => json['id'] == bookmarkId);
    bookmarksMap[bookId] = bookBookmarks;

    await prefs.setString(_bookmarksKey, jsonEncode(bookmarksMap));
  }

  // 阅读进度管理
  static Future<ReadingPosition?> getReadingPosition(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final positionsJson = prefs.getString(_readingPositionsKey) ?? '{}';
    final positionsMap = jsonDecode(positionsJson) as Map<String, dynamic>;

    final positionJson = positionsMap[bookId];
    if (positionJson != null) {
      return ReadingPosition.fromJson(positionJson);
    }
    return null;
  }

  static Future<void> saveReadingPosition(
    String bookId,
    ReadingPosition position,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final positionsJson = prefs.getString(_readingPositionsKey) ?? '{}';
    final positionsMap = jsonDecode(positionsJson) as Map<String, dynamic>;

    positionsMap[bookId] = position.toJson();
    await prefs.setString(_readingPositionsKey, jsonEncode(positionsMap));
  }

  // 生成唯一ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
