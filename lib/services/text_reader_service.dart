import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html;

class Chapter {
  final String title;
  final String content;
  final String? htmlContent;
  final int index;

  Chapter({
    required this.title, 
    required this.content, 
    this.htmlContent,
    required this.index
  });
}

class TextReaderService {
  static TextReaderService? _instance;

  TextReaderService._();

  static TextReaderService get instance {
    return _instance ??= TextReaderService._();
  }

  Future<List<Chapter>> readBookChapters(
    String filePath,
    String fileType,
  ) async {
    try {
      // Validate file path
      if (filePath.isEmpty) {
        throw Exception('File path is empty');
      }

      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        throw Exception('Book file not found: $filePath');
      }

      switch (fileType.toLowerCase()) {
        case 'txt':
        case 'text':
        case 'plain':
          return await _readTextFileChapters(file);
        case 'epub':
          return await _readEpubFileChapters(file);
        default:
          debugPrint('Unknown file type: $fileType, falling back to text');
          return await _readTextFileChapters(file);
      }
    } catch (e) {
      debugPrint('Error reading book chapters: $e');
      return [Chapter(title: 'Error', content: _getErrorContent(), index: 0)];
    }
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
        throw Exception('Book file not found: $filePath');
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

  Future<List<Chapter>> _readTextFileChapters(File file) async {
    try {
      final content = await _readTextFile(file);
      return _detectChaptersFromText(content);
    } catch (e) {
      debugPrint('Error reading text file chapters: $e');
      return [
        Chapter(title: 'Full Content', content: _getErrorContent(), index: 0),
      ];
    }
  }

  Future<List<Chapter>> _readEpubFileChapters(File file) async {
    try {
      debugPrint('Reading EPUB file: ${file.path}');
      final bytes = await file.readAsBytes();
      debugPrint('EPUB file size: ${bytes.length} bytes');
      
      final epub = await EpubReader.readBook(bytes);
      debugPrint('EPUB loaded successfully');
      debugPrint('EPUB Title: ${epub.Title}');
      debugPrint('EPUB Author: ${epub.Author}');
      debugPrint('EPUB Chapters count: ${epub.Chapters?.length ?? 0}');

      final chapters = <Chapter>[];

      // Extract chapters from EPUB structure
      if (epub.Chapters != null && epub.Chapters!.isNotEmpty) {
        debugPrint('Extracting from EPUB chapters structure...');
        for (int i = 0; i < epub.Chapters!.length; i++) {
          final chapter = epub.Chapters![i];
          final htmlContent = chapter.HtmlContent ?? '';
          debugPrint('Chapter ${i + 1}: ${chapter.Title}, HTML length: ${htmlContent.length}');
          
          final chapterContent = _extractTextFromHtml(htmlContent);
          debugPrint('Extracted text length: ${chapterContent.length}');

          // Lower the minimum content length threshold
          if (chapterContent.trim().isNotEmpty && chapterContent.length > 20) {
            chapters.add(
              Chapter(
                title: chapter.Title?.isNotEmpty == true
                    ? chapter.Title!
                    : 'Chapter ${i + 1}',
                content: sanitizeText(chapterContent),
                htmlContent: _cleanHtmlForRendering(htmlContent),
                index: i,
              ),
            );
            debugPrint('Added chapter: ${chapter.Title}');
          } else {
            debugPrint('Skipped chapter ${i + 1} - insufficient content');
          }
        }
      }

      debugPrint('Total chapters extracted: ${chapters.length}');

      if (chapters.isEmpty) {
        debugPrint('No chapters found, returning error content');
        return [
          Chapter(
            title: 'No Content Found', 
            content: 'Unable to extract readable content from this EPUB file. The file may be corrupted or use an unsupported format.\n\nTry using a different EPUB file or convert it to a text file.',
            index: 0
          ),
        ];
      }

      return chapters;
    } catch (e) {
      debugPrint('Error reading EPUB file chapters: $e');
      return [
        Chapter(
          title: 'Error', 
          content: 'Failed to read EPUB file: ${e.toString()}\n\nThis may be due to:\n- Corrupted EPUB file\n- Unsupported EPUB format\n- File access permissions\n\nPlease try re-importing the book.',
          index: 0
        )
      ];
    }
  }

  String? _extractChapterTitle(String htmlContent) {
    try {
      final document = html.parse(htmlContent);
      
      // Try to find title in various elements, in order of preference
      final titleSelectors = [
        'h1',
        'h2', 
        'h3',
        '.chapter-title',
        '.title',
        '.chapter',
        '[class*="title"]',
        '[class*="chapter"]',
        'title'
      ];
      
      for (final selector in titleSelectors) {
        final elements = document.querySelectorAll(selector);
        if (elements.isNotEmpty) {
          final title = elements.first.text.trim();
          if (title.isNotEmpty && title.length < 200 && title.length > 1) {
            // Filter out common non-title content
            final lowerTitle = title.toLowerCase();
            if (!lowerTitle.contains('copyright') && 
                !lowerTitle.contains('table of contents') &&
                !lowerTitle.contains('toc') &&
                !lowerTitle.startsWith('page ') &&
                !RegExp(r'^\d+$').hasMatch(title)) {
              return title;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error extracting chapter title: $e');
      return null;
    }
  }

  List<Chapter> _detectChaptersFromText(String content) {
    // Common chapter patterns
    final chapterPatterns = [
      RegExp(r'^Chapter\s+\d+.*$', multiLine: true, caseSensitive: false),
      RegExp(r'^第[一二三四五六七八九十\d]+章.*$', multiLine: true), // Chinese chapters
      RegExp(r'^\d+\.\s+.*$', multiLine: true), // Numbered sections
      RegExp(r'^[A-Z][A-Z\s]+$', multiLine: true), // All caps titles
    ];

    final chapters = <Chapter>[];

    // Try to find chapters using patterns
    for (final pattern in chapterPatterns) {
      final matches = pattern.allMatches(content);
      if (matches.length > 1) {
        // Need at least 2 matches to consider it valid
        final matchList = matches.toList();

        for (int i = 0; i < matchList.length; i++) {
          final match = matchList[i];
          final title = match.group(0)?.trim() ?? 'Chapter ${i + 1}';

          final startIndex = match.start;
          final endIndex = i < matchList.length - 1
              ? matchList[i + 1].start
              : content.length;

          final chapterContent = content.substring(startIndex, endIndex).trim();

          if (chapterContent.length > 100) {
            // Minimum chapter length
            chapters.add(
              Chapter(
                title: title,
                content: sanitizeText(chapterContent),
                index: i,
              ),
            );
          }
        }

        if (chapters.isNotEmpty) {
          return chapters; // Return first successful pattern match
        }
      }
    }

    // If no chapters detected, split into sections by length
    return _splitTextIntoSections(content);
  }

  List<Chapter> _splitTextIntoSections(
    String content, {
    int wordsPerSection = 3000,
  }) {
    final words = content.split(RegExp(r'\s+'));
    final chapters = <Chapter>[];

    for (int i = 0; i < words.length; i += wordsPerSection) {
      final endIndex = (i + wordsPerSection < words.length)
          ? i + wordsPerSection
          : words.length;

      final sectionWords = words.sublist(i, endIndex);
      final sectionContent = sectionWords.join(' ');

      chapters.add(
        Chapter(
          title: 'Section ${(i ~/ wordsPerSection) + 1}',
          content: sanitizeText(sectionContent),
          index: i ~/ wordsPerSection,
        ),
      );
    }

    return chapters.isEmpty
        ? [
            Chapter(
              title: 'Full Content',
              content: sanitizeText(content),
              index: 0,
            ),
          ]
        : chapters;
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
          final chapterContent = _extractTextFromHtml(
            chapter.HtmlContent ?? '',
          );
          if (chapterContent.trim().isNotEmpty) {
            textContent.add(chapterContent);
          }
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
    try {
      // Parse HTML content
      final document = html.parse(htmlContent);

      // Remove script and style elements
      final scripts = document.querySelectorAll('script');
      final styles = document.querySelectorAll('style');
      for (final element in scripts) {
        element.remove();
      }
      for (final element in styles) {
        element.remove();
      }

      // Process text content with proper formatting
      final body = document.body ?? document;
      String text = _extractFormattedText(body);

      // Clean up excessive whitespace while preserving paragraphs
      text = text
          .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces and tabs
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max 2 consecutive newlines
          .trim();

      return text;
    } catch (e) {
      debugPrint('Error parsing HTML: $e');
      // Fallback to simple regex-based extraction
      return _fallbackHtmlExtraction(htmlContent);
    }
  }

  String _extractFormattedText(dynamic element) {
    if (element == null) return '';
    
    final buffer = StringBuffer();
    
    // Handle different node types
    try {
      if (element.nodes != null) {
        for (final node in element.nodes) {
          if (node.nodeType == 3) { // Text node
            final text = node.text?.trim() ?? '';
            if (text.isNotEmpty) {
              buffer.write(text);
            }
          } else if (node.nodeType == 1) { // Element node
            final tagName = node.localName?.toLowerCase() ?? '';
            
            // Add paragraph breaks for block elements
            if (['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'article', 'section', 'blockquote'].contains(tagName)) {
              if (buffer.isNotEmpty && !buffer.toString().endsWith('\n\n')) {
                buffer.write('\n\n');
              }
              final childText = _extractFormattedText(node);
              if (childText.trim().isNotEmpty) {
                buffer.write(childText.trim());
                buffer.write('\n\n');
              }
            }
            // Add line breaks for br elements
            else if (tagName == 'br') {
              buffer.write('\n');
            }
            // Add list formatting
            else if (tagName == 'li') {
              buffer.write('\n• ');
              buffer.write(_extractFormattedText(node));
            }
            else if (['ul', 'ol'].contains(tagName)) {
              buffer.write('\n');
              buffer.write(_extractFormattedText(node));
              buffer.write('\n');
            }
            // Handle table elements
            else if (tagName == 'td' || tagName == 'th') {
              buffer.write('\t');
              buffer.write(_extractFormattedText(node));
            }
            else if (tagName == 'tr') {
              buffer.write('\n');
              buffer.write(_extractFormattedText(node));
            }
            // Regular inline elements
            else {
              buffer.write(_extractFormattedText(node));
            }
          }
        }
      } else if (element.text != null) {
        // Fallback for simple text content
        buffer.write(element.text);
      }
    } catch (e) {
      debugPrint('Error in _extractFormattedText: $e');
      // Fallback to simple text extraction
      if (element.text != null) {
        buffer.write(element.text);
      }
    }
    
    return buffer.toString();
  }

  String _fallbackHtmlExtraction(String htmlContent) {
    String text = htmlContent;

    // Remove script and style tags with their content
    text = text
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            multiLine: true,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?</style>',
            caseSensitive: false,
            multiLine: true,
            dotAll: true,
          ),
          '',
        );

    // Convert block-level elements to paragraph breaks
    final blockElements = [
      'p',
      'div',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'article',
      'section',
      'header',
      'footer',
      'main',
      'blockquote',
      'pre',
      'address',
    ];

    for (final element in blockElements) {
      // Convert opening and closing tags to double line breaks
      text = text
          .replaceAll(
            RegExp(r'<' + element + r'[^>]*>', caseSensitive: false),
            '\n\n',
          )
          .replaceAll(
            RegExp(r'</' + element + r'>', caseSensitive: false),
            '\n\n',
          );
    }

    // Convert line break elements
    text = text
        .replaceAll(RegExp(r'<br[^>]*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<hr[^>]*/?>', caseSensitive: false), '\n---\n');

    // Convert list elements
    text = text
        .replaceAll(RegExp(r'<ul[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<ol[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '');

    // Convert table elements
    text = text
        .replaceAll(RegExp(r'<table[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</table>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<tr[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</tr>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<td[^>]*>', caseSensitive: false), '\t')
        .replaceAll(RegExp(r'</td>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<th[^>]*>', caseSensitive: false), '\t')
        .replaceAll(RegExp(r'</th>', caseSensitive: false), '');

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode HTML entities
    text = text
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'&apos;'), "'")
        .replaceAll(RegExp(r'&mdash;'), '—')
        .replaceAll(RegExp(r'&ndash;'), '–')
        .replaceAll(RegExp(r'&hellip;'), '…')
        .replaceAll(RegExp(r'&ldquo;'), '"')
        .replaceAll(RegExp(r'&rdquo;'), '"')
        .replaceAll(RegExp(r'&lsquo;'), ''')
        .replaceAll(RegExp(r'&rsquo;'), ''');

    // Handle numeric HTML entities (like &#8220;)
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final charCode = int.parse(match.group(1)!);
        return String.fromCharCode(charCode);
      } catch (e) {
        return match.group(0)!; // Return original if parsing fails
      }
    });

    // Handle hex HTML entities (like &#x201C;)
    text = text.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      try {
        final charCode = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(charCode);
      } catch (e) {
        return match.group(0)!; // Return original if parsing fails
      }
    });

    return text.trim();
  }

  String _cleanHtmlForRendering(String htmlContent) {
    try {
      // Parse HTML content
      final document = html.parse(htmlContent);

      // Remove script and style elements
      final scripts = document.querySelectorAll('script');
      final styles = document.querySelectorAll('style');
      for (final element in scripts) {
        element.remove();
      }
      for (final element in styles) {
        element.remove();
      }

      // Get the body content or full document if no body
      final bodyElement = document.body ?? document.documentElement;
      if (bodyElement == null) return htmlContent;

      // Return cleaned HTML content
      return bodyElement.innerHtml;
    } catch (e) {
      debugPrint('Error cleaning HTML: $e');
      // Return original content if parsing fails
      return htmlContent;
    }
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
    // Normalize line breaks first
    String sanitized = text.replaceAll(RegExp(r'\r\n|\r'), '\n');

    // Clean up excessive whitespace while preserving paragraph structure
    // Replace multiple spaces/tabs with single space
    sanitized = sanitized.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Clean up excessive line breaks but preserve paragraph separation
    // Replace 3+ consecutive newlines with just 2 (paragraph break)
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove spaces at the beginning and end of lines
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'^[ \t]+|[ \t]+$', multiLine: true),
      (match) => '',
    );

    // Remove empty lines that only contain whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\n[ \t]*\n'), '\n\n');

    return sanitized.trim();
  }
}