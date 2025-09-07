import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart' as epubx;

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

  // 添加回调列表来通知数据变化
  final List<VoidCallback> _dataChangeListeners = [];

  BookService._();

  static BookService get instance {
    return _instance ??= BookService._();
  }

  /// 添加数据变化监听器
  void addDataChangeListener(VoidCallback listener) {
    _dataChangeListeners.add(listener);
  }

  /// 移除数据变化监听器
  void removeDataChangeListener(VoidCallback listener) {
    _dataChangeListeners.remove(listener);
  }

  /// 通知所有监听器数据已变化
  void _notifyDataChanged() {
    debugPrint('=== 开始通知数据变化 ===');
    debugPrint('监听器数量: ${_dataChangeListeners.length}');

    for (int i = 0; i < _dataChangeListeners.length; i++) {
      try {
        debugPrint('通知监听器 $i');
        _dataChangeListeners[i]();
        debugPrint('监听器 $i 通知完成');
      } catch (e) {
        debugPrint('通知监听器 $i 时出错: $e');
      }
    }

    debugPrint('=== 数据变化通知完成 ===');
  }

  Future<List<Book>> getBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList(_booksKey) ?? [];

      final books = booksJson.map((bookJson) {
        final map = json.decode(bookJson) as Map<String, dynamic>;
        return Book.fromJson(map);
      }).toList();

      // 自动清理无效的书籍记录
      return await _cleanupInvalidBooks(books);
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

      // 通知数据变化
      _notifyDataChanged();
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }

  Future<Book?> importBook() async {
    try {
      debugPrint('=== 开始导入书籍 ===');

      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: false,
      );

      if (result?.files.isEmpty ?? true) {
        debugPrint('用户取消了文件选择');
        return null;
      }

      final file = result!.files.first;
      if (file.path == null) {
        debugPrint('错误: 文件路径为空');
        return null;
      }

      debugPrint('选择的文件: ${file.name}');
      debugPrint('文件大小: ${file.size} bytes');
      debugPrint('文件路径: ${file.path}');

      // 验证文件
      final sourceFile = File(file.path!);
      if (!await sourceFile.exists()) {
        debugPrint('错误: 源文件不存在');
        return null;
      }

      // 复制到应用目录
      debugPrint('开始复制文件到应用目录...');
      final newFilePath = await _copyToBooksDirectory(
        sourceFile,
        file.extension,
      );
      if (newFilePath == null) {
        debugPrint('错误: 文件复制失败');
        return null;
      }
      debugPrint('文件复制成功: $newFilePath');

      // 提取元数据和封面
      debugPrint('开始提取元数据...');
      final metadata = await _extractMetadataFromEpub(newFilePath);
      debugPrint('元数据提取完成: $metadata');

      debugPrint('开始提取封面图片...');
      final coverImagePath = await _extractAndSaveCoverImage(newFilePath);
      debugPrint('封面图片提取结果: $coverImagePath');

      final book = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: metadata['title'] ?? 'Unknown Title',
        author: metadata['author'] ?? 'Unknown Author',
        filePath: newFilePath,
        coverImagePath: coverImagePath,
        progress: 0.0,
        importDate: DateTime.now(),
        fileType: 'epub',
        fileSize: file.size,
      );

      debugPrint('创建书籍对象完成: ${book.title}');
      debugPrint('封面路径: ${book.coverImagePath}');

      // 保存到列表
      final books = await getBooks();
      books.add(book);
      await saveBooks(books);
      debugPrint('书籍保存到列表完成');

      debugPrint('=== 书籍导入完成 ===');
      return book;
    } catch (e, stackTrace) {
      debugPrint('=== 书籍导入失败 ===');
      debugPrint('错误信息: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  Future<String?> _copyToBooksDirectory(
    File sourceFile,
    String? extension,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = extension?.toLowerCase() ?? 'epub';
      final newFilePath = '${booksDir.path}/$bookId.$fileExtension';

      await sourceFile.copy(newFilePath);
      return newFilePath;
    } catch (e) {
      debugPrint('Error copying file: $e');
      return null;
    }
  }

  Future<Map<String, String>> _extractMetadataFromEpub(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final epubBook = await epubx.EpubReader.readBook(bytes);

      return {
        'title': epubBook.Title ?? 'Unknown Title',
        'author': epubBook.Author ?? 'Unknown Author',
        'identifier':
            epubBook
                .Schema
                ?.Package
                ?.Metadata
                ?.Identifiers
                ?.firstOrNull
                ?.Identifier ??
            'unknown',
      };
    } catch (e) {
      debugPrint('Error extracting metadata: $e');
      return {
        'title': 'Unknown Title',
        'author': 'Unknown Author',
        'identifier': 'unknown',
      };
    }
  }

  /// 使用epubx API提取并保存封面图片
  Future<String?> _extractAndSaveCoverImage(String filePath) async {
    try {
      debugPrint('=== 开始提取封面图片 ===');
      debugPrint('文件路径: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('错误: 文件不存在');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('文件大小: $fileSize bytes');

      final bytes = await file.readAsBytes();
      debugPrint('读取文件字节完成，大小: ${bytes.length} bytes');

      final epubBook = await epubx.EpubReader.readBook(bytes);
      debugPrint('EPUB解析完成');
      debugPrint('书籍标题: ${epubBook.Title}');
      debugPrint('书籍作者: ${epubBook.Author}');

      // 使用epubx的封面获取功能
      debugPrint('开始获取封面图片...');
      final coverImageContent = epubBook.CoverImage;

      if (coverImageContent == null) {
        debugPrint('警告: EPUB中没有找到封面图片');

        // 尝试其他方法查找封面
        debugPrint('尝试从图片资源中查找封面...');
        final images = epubBook.Content?.Images ?? {};
        debugPrint('找到 ${images.length} 个图片资源');

        for (final entry in images.entries) {
          final fileName = entry.key;
          debugPrint('图片文件: $fileName');

          // 检查是否是常见的封面文件名
          final lowerFileName = fileName.toLowerCase();
          if (lowerFileName.contains('cover') ||
              lowerFileName.contains('title') ||
              lowerFileName == 'cover.jpg' ||
              lowerFileName == 'cover.png' ||
              lowerFileName == 'title.jpg' ||
              lowerFileName == 'title.png') {
            debugPrint('找到可能的封面文件: $fileName');

            final imageContent = entry.value;
            if (imageContent.Content != null &&
                imageContent.Content!.isNotEmpty) {
              debugPrint('使用图片资源作为封面: $fileName');
              return await _saveCoverFromImageResource(
                imageContent.Content!,
                fileName,
              );
            }
          }
        }

        debugPrint('未找到任何封面图片');
        return null;
      }

      debugPrint('找到封面图片内容');

      // 获取封面图片字节数据
      debugPrint('开始获取封面图片字节数据...');
      final coverBytes = coverImageContent.getBytes();
      debugPrint('封面图片字节数据大小: ${coverBytes.length} bytes');

      if (coverBytes.isEmpty) {
        debugPrint('错误: 封面图片字节数据为空');
        return null;
      }

      // 验证图片数据是否有效
      if (!_isValidImageData(coverBytes)) {
        debugPrint('错误: 封面图片数据无效，尝试从图片资源中查找...');

        // 如果封面数据无效，尝试从图片资源中查找
        final images = epubBook.Content?.Images ?? {};
        for (final entry in images.entries) {
          final fileName = entry.key;
          final imageContent = entry.value;
          if (imageContent.Content != null &&
              imageContent.Content!.isNotEmpty) {
            if (_isValidImageData(imageContent.Content!)) {
              debugPrint('找到有效的图片资源: $fileName');
              return await _saveCoverFromImageResource(
                imageContent.Content!,
                fileName,
              );
            }
          }
        }

        debugPrint('未找到有效的封面图片');
        return null;
      }

      // 保存封面图片到应用目录
      debugPrint('开始保存封面图片...');
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/covers');
      debugPrint('封面目录: ${coversDir.path}');

      if (!await coversDir.exists()) {
        debugPrint('创建封面目录...');
        await coversDir.create(recursive: true);
        debugPrint('封面目录创建完成');
      }

      // 生成封面文件名
      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final coverFileName = '${bookId}_cover.jpg';
      final coverFilePath = '${coversDir.path}/$coverFileName';
      debugPrint('封面文件路径: $coverFilePath');

      // 写入封面文件
      final coverFile = File(coverFilePath);
      await coverFile.writeAsBytes(coverBytes);
      debugPrint('封面图片保存成功: $coverFilePath');

      // 验证文件是否真的保存了
      if (await coverFile.exists()) {
        final savedFileSize = await coverFile.length();
        debugPrint('验证: 保存的封面文件大小: $savedFileSize bytes');

        // 再次验证保存的图片数据是否有效
        final savedBytes = await coverFile.readAsBytes();
        if (!_isValidImageData(savedBytes)) {
          debugPrint('错误: 保存的封面图片数据无效，删除文件');
          await coverFile.delete();
          return null;
        }
      } else {
        debugPrint('错误: 封面文件保存后不存在');
        return null;
      }

      debugPrint('=== 封面图片提取完成 ===');
      return coverFilePath;
    } catch (e, stackTrace) {
      debugPrint('=== 封面图片提取失败 ===');
      debugPrint('错误信息: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 从图片资源保存封面
  Future<String?> _saveCoverFromImageResource(
    List<int> imageBytes,
    String fileName,
  ) async {
    try {
      debugPrint('从图片资源保存封面: $fileName');

      // 验证图片数据是否有效
      if (!_isValidImageData(imageBytes)) {
        debugPrint('错误: 图片资源数据无效');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/covers');

      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      // 获取文件扩展名
      final extension = fileName.split('.').last.toLowerCase();
      final bookId = DateTime.now().millisecondsSinceEpoch.toString();
      final coverFileName = '${bookId}_cover.$extension';
      final coverFilePath = '${coversDir.path}/$coverFileName';

      final coverFile = File(coverFilePath);
      await coverFile.writeAsBytes(imageBytes);

      // 验证保存的文件
      if (await coverFile.exists()) {
        final savedBytes = await coverFile.readAsBytes();
        if (!_isValidImageData(savedBytes)) {
          debugPrint('错误: 保存的图片资源数据无效，删除文件');
          await coverFile.delete();
          return null;
        }
      }

      debugPrint('从图片资源保存封面成功: $coverFilePath');
      return coverFilePath;
    } catch (e) {
      debugPrint('从图片资源保存封面失败: $e');
      return null;
    }
  }

  /// 验证图片数据是否有效
  bool _isValidImageData(List<int> bytes) {
    if (bytes.isEmpty) return false;

    // 检查常见的图片文件头
    // JPEG: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    // GIF: 47 49 46 38
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }

  Future<List<Book>> _cleanupInvalidBooks(List<Book> books) async {
    final validBooks = <Book>[];
    bool hasChanges = false;

    for (final book in books) {
      if (await File(book.filePath).exists()) {
        validBooks.add(book);
      } else {
        hasChanges = true;
        debugPrint('Removing invalid book: ${book.title}');
      }
    }

    if (hasChanges) {
      await saveBooks(validBooks);
    }

    return validBooks;
  }

  // 为了向后兼容，保留这个方法
  Future<List<Book>> getValidatedBooks() async {
    return await getBooks();
  }

  Future<void> cleanupInvalidBooks() async {
    final books = await getBooks();
    final validBooks = <Book>[];
    bool hasChanges = false;

    for (final book in books) {
      if (await File(book.filePath).exists()) {
        validBooks.add(book);
      } else {
        hasChanges = true;
        debugPrint('Removing invalid book: ${book.title}');

        // 删除对应的封面图片文件
        if (book.coverImagePath != null) {
          await _deleteCoverImage(book.coverImagePath!);
        }
      }
    }

    if (hasChanges) {
      await saveBooks(validBooks);
    }
  }

  /// 删除封面图片文件
  Future<void> _deleteCoverImage(String coverImagePath) async {
    try {
      final coverFile = File(coverImagePath);
      if (await coverFile.exists()) {
        await coverFile.delete();
        debugPrint('Deleted cover image: $coverImagePath');
      }
    } catch (e) {
      debugPrint('Error deleting cover image: $e');
    }
  }

  /// 清空所有数据（包括书籍、封面图片、书签等）
  Future<void> clearAllData() async {
    try {
      debugPrint('=== BookService开始清空所有数据 ===');

      // 获取所有书籍
      final books = await getBooks();
      debugPrint('当前书籍数量: ${books.length}');

      // 删除所有封面图片文件
      for (final book in books) {
        if (book.coverImagePath != null) {
          await _deleteCoverImage(book.coverImagePath!);
        }
      }

      // 删除整个covers目录
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/covers');
      if (await coversDir.exists()) {
        await coversDir.delete(recursive: true);
        debugPrint('Deleted covers directory');
      }

      // 删除整个books目录
      final booksDir = Directory('${appDir.path}/books');
      if (await booksDir.exists()) {
        await booksDir.delete(recursive: true);
        debugPrint('Deleted books directory');
      }

      // 清空SharedPreferences中的书籍数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_booksKey);
      debugPrint('Cleared books data from SharedPreferences');

      // 清空书签数据（如果有BookmarkService的话）
      // await BookmarkService.instance.clearAllBookmarks();

      debugPrint('=== BookService所有数据清空完成 ===');

      // 通知数据变化
      debugPrint('准备通知数据变化，监听器数量: ${_dataChangeListeners.length}');
      _notifyDataChanged();
      debugPrint('数据变化通知已发送');
    } catch (e) {
      debugPrint('BookService清空数据失败: $e');
      rethrow;
    }
  }

  /// 删除指定书籍及其相关文件
  Future<bool> deleteBook(String bookId) async {
    try {
      final books = await getBooks();
      final bookIndex = books.indexWhere((book) => book.id == bookId);

      if (bookIndex == -1) {
        debugPrint('Book not found: $bookId');
        return false;
      }

      final book = books[bookIndex];

      // 删除书籍文件
      final bookFile = File(book.filePath);
      if (await bookFile.exists()) {
        await bookFile.delete();
        debugPrint('Deleted book file: ${book.filePath}');
      }

      // 删除封面图片文件
      if (book.coverImagePath != null) {
        await _deleteCoverImage(book.coverImagePath!);
      }

      // 从列表中移除
      books.removeAt(bookIndex);
      await saveBooks(books);

      debugPrint('Book deleted successfully: ${book.title}');
      return true;
    } catch (e) {
      debugPrint('Error deleting book: $e');
      return false;
    }
  }
}
