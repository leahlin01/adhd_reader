import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'text_reader_service.dart';

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
      final booksJson = books
          .map((book) => json.encode(book.toJson()))
          .toList();
      await prefs.setStringList(_booksKey, booksJson);
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }

  Future<Book?> importBook() async {
    try {
      // 支持的文件扩展名（主要是EPUB）
      final supportedExtensions = ['epub'];
      debugPrint('Supported extensions: $supportedExtensions');

      // 尝试多种文件选择策略
      FilePickerResult? result;

      // 首先尝试使用支持的扩展名
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
      );

      // 如果第一次尝试失败，尝试使用所有文件类型
      if (result == null || result.files.isEmpty) {
        debugPrint(
          'First file picker attempt failed, trying with all files...',
        );
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return null;
      }

      final file = result.files.first;
      debugPrint(
        'Selected file: ${file.name}, extension: ${file.extension}, size: ${file.size}',
      );

      // Validate the selected file
      if (file.path == null || file.path!.isEmpty) {
        debugPrint('Selected file has no path');
        return null;
      }

      final platformFile = File(file.path!);

      // Check if source file exists
      if (!await platformFile.exists()) {
        debugPrint('Source file does not exist: ${file.path}');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');

      // Ensure books directory exists
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
        debugPrint('Created books directory: ${booksDir.path}');
      }

      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = file.extension?.toLowerCase() ?? 'txt';
      final newFilePath = '${booksDir.path}/$bookId.$fileExtension';

      debugPrint('Copying file from ${file.path} to $newFilePath');

      // Copy the file
      try {
        await platformFile.copy(newFilePath);
        debugPrint('File copied successfully');
      } catch (e) {
        debugPrint('Error copying file: $e');
        return null;
      }

      // Verify the copied file exists
      final copiedFile = File(newFilePath);
      if (!await copiedFile.exists()) {
        debugPrint('Copied file does not exist: $newFilePath');
        return null;
      }

      // 检测文件类型
      final fileType = fileExtension == 'epub' ? 'epub' : 'txt';

      // 验证文件格式是否支持（目前主要支持EPUB）
      if (fileExtension != 'epub') {
        debugPrint('Unsupported file format: $fileType');
        // Delete the copied file since it's not supported
        await copiedFile.delete();
        return null;
      }

      debugPrint('File type detected: $fileType (extension: $fileExtension)');
      debugPrint('Original filename: ${file.name}');

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

      debugPrint(
        'Book imported successfully: ${book.title} at ${book.filePath}',
      );

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

  Future<void> updateBookMetadata(
    String bookId, {
    String? title,
    String? author,
  }) async {
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

  String? _getFileTypeFromExtension(String extension) {
    // Normalize extension to lowercase for consistent comparison
    final normalizedExtension = extension.toLowerCase().trim();

    switch (normalizedExtension) {
      case 'epub':
      case 'epub3':
      case 'epub2':
        return 'epub';
      case 'txt':
      case 'text':
      case 'md':
      case 'markdown':
      case 'copying':
      case 'license':
      case 'readme':
      case 'log':
      case 'COPYING': // Handle uppercase extensions
      case 'LICENSE':
      case 'README':
      case 'LOG':
        return 'txt';
      default:
        // 如果扩展名不在已知列表中，尝试通过文件名模式判断
        if (normalizedExtension.contains('epub')) {
          return 'epub';
        }
        return null; // Unknown extension, fallback to MIME detection
    }
  }

  String _getFileTypeFromMime(String mimeType) {
    final lowerMime = mimeType.toLowerCase();

    if (lowerMime.contains('epub') ||
        lowerMime.contains('application/epub+zip') ||
        lowerMime.contains('application/x-epub')) {
      return 'epub';
    }
    if (lowerMime.contains('text') ||
        lowerMime.contains('plain') ||
        lowerMime.contains('application/text')) {
      return 'txt';
    }
    return 'txt'; // Default to text for unknown types
  }

  List<Book> searchBooks(List<Book> books, String query) {
    if (query.isEmpty) return books;

    final lowercaseQuery = query.toLowerCase();
    return books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
          book.author.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Validates and fixes book file paths
  Future<List<Book>> validateAndFixBookPaths() async {
    try {
      final books = await getBooks();
      final validBooks = <Book>[];
      bool hasChanges = false;

      for (final book in books) {
        final file = File(book.filePath);

        if (await file.exists()) {
          validBooks.add(book);
        } else {
          debugPrint(
            'Book file not found, removing: ${book.title} at ${book.filePath}',
          );
          hasChanges = true;

          // Try to find the file in the books directory
          final appDir = await getApplicationDocumentsDirectory();
          final booksDir = Directory('${appDir.path}/books');

          if (await booksDir.exists()) {
            final files = await booksDir.list().toList();
            final fileName = book.filePath.split('/').last;

            for (final entity in files) {
              if (entity is File && entity.path.split('/').last == fileName) {
                // Found the file, update the path
                final updatedBook = book.copyWith(filePath: entity.path);
                validBooks.add(updatedBook);
                debugPrint('Fixed book path: ${book.title} -> ${entity.path}');
                hasChanges = true;
                break;
              }
            }
          }
        }
      }

      if (hasChanges) {
        await saveBooks(validBooks);
        debugPrint('Updated book list after path validation');
      }

      return validBooks;
    } catch (e) {
      debugPrint('Error validating book paths: $e');
      return await getBooks(); // Return original list on error
    }
  }

  /// Gets books with automatic path validation
  Future<List<Book>> getValidatedBooks() async {
    return await validateAndFixBookPaths();
  }

  /// Cleans up invalid book records (books with missing files)
  Future<void> cleanupInvalidBooks() async {
    try {
      final books = await getBooks();
      final validBooks = <Book>[];
      bool hasChanges = false;

      for (final book in books) {
        final file = File(book.filePath);
        if (await file.exists()) {
          validBooks.add(book);
        } else {
          debugPrint(
            'Removing invalid book: ${book.title} (file not found: ${book.filePath})',
          );
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await saveBooks(validBooks);
        debugPrint('Cleaned up invalid books. Remaining: ${validBooks.length}');
      }
    } catch (e) {
      debugPrint('Error cleaning up invalid books: $e');
    }
  }

  /// Gets the total size of all book files
  Future<int> getTotalBooksSize() async {
    try {
      final books = await getValidatedBooks();
      int totalSize = 0;

      for (final book in books) {
        final file = File(book.filePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating total books size: $e');
      return 0;
    }
  }

  /// 专门用于测试epub文件选择的方法
  Future<Book?> importEpubBook() async {
    try {
      debugPrint('Attempting to import EPUB book...');

      // 尝试多种epub文件选择策略
      FilePickerResult? result;

      // 策略1: 使用自定义扩展名，只允许epub
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'EPUB'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('Strategy 1 failed, trying strategy 2...');

        // 策略2: 使用所有文件类型，但过滤epub
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final extension = file.extension?.toLowerCase() ?? '';

          if (!extension.contains('epub')) {
            debugPrint(
              'Selected file is not EPUB: ${file.name} (${file.extension})',
            );
            return null;
          }
        }
      }

      if (result == null || result.files.isEmpty) {
        debugPrint('No EPUB file selected');
        return null;
      }

      final file = result.files.first;
      debugPrint(
        'EPUB file selected: ${file.name}, extension: ${file.extension}, size: ${file.size}',
      );

      // 验证文件
      if (file.path == null || file.path!.isEmpty) {
        debugPrint('Selected EPUB file has no path');
        return null;
      }

      final platformFile = File(file.path!);
      if (!await platformFile.exists()) {
        debugPrint('EPUB file does not exist: ${file.path}');
        return null;
      }

      // 复制文件到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final newFilePath = '${booksDir.path}/$bookId.epub';

      try {
        await platformFile.copy(newFilePath);
        debugPrint('EPUB file copied successfully to: $newFilePath');
      } catch (e) {
        debugPrint('Error copying EPUB file: $e');
        return null;
      }

      // 创建书籍记录
      final book = Book(
        id: bookId,
        title: _extractTitleFromFilename(file.name),
        author: 'Unknown Author',
        filePath: newFilePath,
        progress: 0.0,
        importDate: DateTime.now(),
        fileType: 'epub',
        fileSize: file.size,
      );

      // 保存到书籍列表
      final books = await getBooks();
      books.add(book);
      await saveBooks(books);

      debugPrint('EPUB book imported successfully: ${book.title}');
      return book;
    } catch (e) {
      debugPrint('Error importing EPUB book: $e');
      return null;
    }
  }
}
