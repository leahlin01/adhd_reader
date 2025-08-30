import 'dart:io';
import 'package:flutter/services.dart';

class BookMetadata {
  final String title;
  final String author;
  final String? description;
  final String? language;
  final String? publisher;
  final String? publishDate;
  final String? identifier;

  BookMetadata({
    required this.title,
    required this.author,
    this.description,
    this.language,
    this.publisher,
    this.publishDate,
    this.identifier,
  });

  @override
  String toString() {
    return 'BookMetadata{title: $title, author: $author, language: $language}';
  }
}

class TextReaderService {
  static TextReaderService? _instance;
  static const MethodChannel _channel = MethodChannel('text_reader');

  BookMetadata? _metadata;
  String? _currentFilePath;

  TextReaderService._();

  static TextReaderService get instance {
    return _instance ??= TextReaderService._();
  }

  BookMetadata? get metadata => _metadata;
  String? get currentFilePath => _currentFilePath;

  /// 加载EPUB文件并提取基本信息
  /// flutter_epub_viewer会处理实际的阅读功能
  Future<bool> loadEpubFile(String filePath) async {
    try {
      print('Loading EPUB file: $filePath');

      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return false;
      }

      // 验证EPUB文件格式
      if (!await validateEpubFile(filePath)) {
        print('Invalid EPUB file format');
        return false;
      }

      _currentFilePath = filePath;

      // 提取基本元数据信息
      await _extractBasicMetadata(filePath);

      print('EPUB loaded successfully');
      print('Metadata: $_metadata');

      return true;
    } catch (e) {
      print('Error loading EPUB: $e');
      return false;
    }
  }

  /// 提取基本的元数据信息
  Future<void> _extractBasicMetadata(String filePath) async {
    try {
      // 从文件名提取基本信息
      final fileName = filePath.split('/').last.replaceAll('.epub', '');

      // 这里可以添加更复杂的元数据提取逻辑
      // 但主要功能由flutter_epub_viewer处理
      _metadata = BookMetadata(
        title: fileName,
        author: 'Unknown Author',
        description: 'EPUB Book',
        language: 'en',
      );
    } catch (e) {
      print('Error extracting metadata: $e');
      _metadata = BookMetadata(
        title: 'Unknown Title',
        author: 'Unknown Author',
      );
    }
  }

  /// 获取当前加载的文件路径（用于flutter_epub_viewer）
  String? getEpubFilePath() {
    return _currentFilePath;
  }

  /// 检查文件是否已加载
  bool isFileLoaded() {
    return _currentFilePath != null;
  }

  /// 验证EPUB文件格式
  Future<bool> validateEpubFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 检查文件扩展名
      if (!filePath.toLowerCase().endsWith('.epub')) {
        return false;
      }

      // 检查文件大小（不能为空）
      final stat = await file.stat();
      if (stat.size == 0) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating EPUB file: $e');
      return false;
    }
  }

  /// 获取文件信息
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = filePath.split('/').last;

      return {
        'name': fileName,
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'type': fileName.toLowerCase().endsWith('.epub') ? 'epub' : 'unknown',
      };
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _metadata = null;
    _currentFilePath = null;
  }

  /// 重置服务状态
  void reset() {
    dispose();
  }
}
