import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:epubx/epubx.dart';

class TextReaderService {
  static TextReaderService? _instance;

  TextReaderService._();

  static TextReaderService get instance {
    return _instance ??= TextReaderService._();
  }

  Future<String> readBookContent(String filePath, String fileType) async {
    try {
      // Validate file path
      if (filePath.isEmpty) {
        throw Exception('File path is empty');
      }

      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        debugPrint('Current working directory: ${Directory.current.path}');

        // Try to get more information about the file
        final parentDir = file.parent;
        if (await parentDir.exists()) {
          final files = await parentDir.list().toList();
          debugPrint('Files in directory ${parentDir.path}:');
          for (final entity in files) {
            debugPrint('  - ${entity.path}');
          }
        } else {
          debugPrint('Parent directory does not exist: ${parentDir.path}');
        }

        throw Exception('Book file not found: $filePath');
      }

      // Check if file is readable
      if (!await file.stat().then((stat) => stat.mode & 0x4 != 0)) {
        throw Exception('File is not readable: $filePath');
      }

      switch (fileType.toLowerCase()) {
        case 'txt':
        case 'text':
        case 'plain':
          return await _readTextFile(file);
        case 'epub':
          return await _readEpubFile(file);
        default:
          debugPrint('Unknown file type: $fileType, falling back to text');
          return await _readTextFile(file);
      }
    } catch (e) {
      debugPrint('Error reading book content: $e');
      return _getErrorContent();
    }
  }

  Future<String> _readTextFile(File file) async {
    try {
      final bytes = await file.readAsBytes();

      // Try UTF-8 first
      try {
        return utf8.decode(bytes);
      } catch (_) {
        // If UTF-8 fails, try Latin-1
        try {
          return latin1.decode(bytes);
        } catch (_) {
          // If both fail, decode as UTF-8 with replacement characters
          return utf8.decode(bytes, allowMalformed: true);
        }
      }
    } catch (e) {
      debugPrint('Error reading text file: $e');
      return _getErrorContent();
    }
  }

  Future<String> _readEpubFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final epub = await EpubReader.readBook(bytes);
      
      final textContent = <String>[];
      
      // Extract text content from all chapters
      if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
        for (final chapter in epub.Chapters!) {
          final chapterContent = _extractTextFromHtml(chapter.HtmlContent ?? '');
          if (chapterContent.trim().isNotEmpty) {
            textContent.add(chapterContent);
          }
        }
      }
      
      // If no chapters found, try reading HTML content directly
      if (textContent.isEmpty && epub.Content != null) {
        try {
          // Try to access HTML files
          final content = epub.Content;
          if (content?.Html != null) {
            for (final htmlFile in content!.Html!.values) {
              // Try to get the content bytes and convert to string
              try {
                if (htmlFile.Content != null) {
                  String htmlContent;
                  // Check if Content is already a String or needs to be decoded
                  if (htmlFile.Content is String) {
                    htmlContent = htmlFile.Content as String;
                  } else if (htmlFile.Content is List<int>) {
                    htmlContent = utf8.decode(htmlFile.Content as List<int>);
                  } else {
                    htmlContent = htmlFile.Content.toString();
                  }
                  
                  final extractedContent = _extractTextFromHtml(htmlContent);
                  if (extractedContent.trim().isNotEmpty) {
                    textContent.add(extractedContent);
                  }
                }
              } catch (e) {
                debugPrint('Error processing HTML file: $e');
                continue;
              }
            }
          }
        } catch (e) {
          debugPrint('Error reading HTML content: $e');
        }
      }
      
      if (textContent.isEmpty) {
        return _getErrorContent();
      }
      
      return textContent.join('\n\n');
      
    } catch (e) {
      debugPrint('Error reading EPUB file: $e');
      return _getErrorContent();
    }
  }
  
  String _extractTextFromHtml(String htmlContent) {
    // Simple HTML tag removal - in production, consider using html package
    return htmlContent
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', 
            caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', 
            caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _getErrorContent() {
    return '''
Unable to load book content.

This could be due to:
- File format not supported
- Corrupted file
- File access permissions
- Encoding issues

Please try reimporting the book or contact support if the problem persists.

You can try the following formats:
- TXT files (plain text)
- EPUB files (electronic books)

The bionic reading feature will work with any text content once it's successfully loaded.
''';
  }

  List<String> splitIntoPages(String content, {int wordsPerPage = 300}) {
    final words = content.split(RegExp(r'\s+'));
    final pages = <String>[];

    for (int i = 0; i < words.length; i += wordsPerPage) {
      final endIndex = (i + wordsPerPage < words.length)
          ? i + wordsPerPage
          : words.length;

      final pageWords = words.sublist(i, endIndex);
      pages.add(pageWords.join(' '));
    }

    return pages.isEmpty ? [''] : pages;
  }

  String sanitizeText(String text) {
    // Remove excessive whitespace and normalize line breaks
    return text
        .replaceAll(RegExp(r'\r\n|\r'), '\n') // Normalize line breaks
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Remove excessive line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces
        .trim();
  }
}
