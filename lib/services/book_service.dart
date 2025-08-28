import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverImagePath;
  final double progress;
  final DateTime importDate;
  final String fileType;
  final int fileSize;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverImagePath,
    required this.progress,
    required this.importDate,
    required this.fileType,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverImagePath': coverImagePath,
      'progress': progress,
      'importDate': importDate.toIso8601String(),
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      filePath: json['filePath'],
      coverImagePath: json['coverImagePath'],
      progress: (json['progress'] as num).toDouble(),
      importDate: DateTime.parse(json['importDate']),
      fileType: json['fileType'],
      fileSize: json['fileSize'],
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? coverImagePath,
    double? progress,
    DateTime? importDate,
    String? fileType,
    int? fileSize,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      progress: progress ?? this.progress,
      importDate: importDate ?? this.importDate,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

class BookService {
  static const String _booksKey = 'user_books';
  static BookService? _instance;
  
  BookService._();
  
  static BookService get instance {
    return _instance ??= BookService._();
  }

  Future<List<Book>> getBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList(_booksKey) ?? [];
      
      return booksJson.map((bookJson) {
        final map = json.decode(bookJson) as Map<String, dynamic>;
        return Book.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Error loading books: $e');
      return [];
    }
  }

  Future<void> saveBooks(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = books.map((book) => json.encode(book.toJson())).toList();
      await prefs.setStringList(_booksKey, booksJson);
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }

  Future<Book?> importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final platformFile = File(file.path!);

      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = file.extension ?? 'txt';
      final newFilePath = '${booksDir.path}/$bookId.$fileExtension';

      await platformFile.copy(newFilePath);

      final mimeType = lookupMimeType(newFilePath) ?? 'text/plain';
      final fileType = _getFileTypeFromMime(mimeType);

      final book = Book(
        id: bookId,
        title: _extractTitleFromFilename(file.name),
        author: 'Unknown Author',
        filePath: newFilePath,
        progress: 0.0,
        importDate: DateTime.now(),
        fileType: fileType,
        fileSize: file.size,
      );

      final books = await getBooks();
      books.add(book);
      await saveBooks(books);

      return book;
    } catch (e) {
      debugPrint('Error importing book: $e');
      return null;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      final books = await getBooks();
      final bookIndex = books.indexWhere((book) => book.id == bookId);
      
      if (bookIndex != -1) {
        final book = books[bookIndex];
        
        final file = File(book.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        if (book.coverImagePath != null) {
          final coverFile = File(book.coverImagePath!);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        }

        books.removeAt(bookIndex);
        await saveBooks(books);
      }
    } catch (e) {
      debugPrint('Error deleting book: $e');
    }
  }

  Future<void> updateBookProgress(String bookId, double progress) async {
    try {
      final books = await getBooks();
      final bookIndex = books.indexWhere((book) => book.id == bookId);
      
      if (bookIndex != -1) {
        books[bookIndex] = books[bookIndex].copyWith(progress: progress);
        await saveBooks(books);
      }
    } catch (e) {
      debugPrint('Error updating book progress: $e');
    }
  }

  Future<void> updateBookMetadata(String bookId, {String? title, String? author}) async {
    try {
      final books = await getBooks();
      final bookIndex = books.indexWhere((book) => book.id == bookId);
      
      if (bookIndex != -1) {
        books[bookIndex] = books[bookIndex].copyWith(
          title: title,
          author: author,
        );
        await saveBooks(books);
      }
    } catch (e) {
      debugPrint('Error updating book metadata: $e');
    }
  }

  String _extractTitleFromFilename(String filename) {
    final nameWithoutExtension = filename.split('.').first;
    return nameWithoutExtension.replaceAll(RegExp(r'[_-]'), ' ').trim();
  }

  String _getFileTypeFromMime(String mimeType) {
    if (mimeType.contains('epub')) return 'EPUB';
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('text')) return 'TXT';
    return 'Unknown';
  }

  List<Book> searchBooks(List<Book> books, String query) {
    if (query.isEmpty) return books;
    
    final lowercaseQuery = query.toLowerCase();
    return books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
             book.author.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}