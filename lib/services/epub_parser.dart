import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:html/parser.dart' as html_parser;

import 'package:path/path.dart' as path;
import '../models/epub_book.dart';
import '../utils/pure_logger.dart';

/// EPUB解析器 - 使用epubx库重构版本
///
/// 提供EPUB文件解析功能，支持：
/// - 元数据提取（标题、作者、标识符等）
/// - 章节内容解析和HTML处理
/// - 图片和其他资源处理
/// - 封面图片识别
class EpubParser {
  /// 从文件路径解析EPUB
  static Future<EpubBook> parseEpubFile(String filePath) async {
    try {
      PureLogger.debug('开始解析EPUB文件: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('EPUB文件不存在', filePath);
      }

      final bytes = await file.readAsBytes();
      return await parseEpubBytes(bytes, fileName: path.basename(filePath));
    } catch (e, stackTrace) {
      PureLogger.error('解析EPUB文件失败: $filePath', e);
      _logStackTrace(stackTrace);
      rethrow;
    }
  }

  /// 从字节数组解析EPUB
  static Future<EpubBook> parseEpubBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    try {
      PureLogger.debug('开始解析EPUB字节数据，大小: ${bytes.length} bytes');

      // 使用epubx库解析
      final epubBook = await epubx.EpubReader.readBook(bytes);
      PureLogger.debug('epubx解析完成');

      // 提取元数据
      final title = epubBook.Title ?? 'Unknown Title';
      final author = epubBook.Author ?? 'Unknown Author';
      final identifier =
          epubBook
              .Schema
              ?.Package
              ?.Metadata
              ?.Identifiers
              ?.firstOrNull
              ?.Identifier ??
          'unknown';

      PureLogger.debug('提取元数据完成: title=$title, author=$author');

      // 处理章节
      final chapters = (epubBook.Chapters ?? []).map((chapter) {
        // 使用epubx.EpubChapter的正确属性
        String title = chapter.Title ?? 'Untitled Chapter';
        String content = chapter.HtmlContent ?? '';

        // 递归处理子章节
        List<EpubChapter> subChapters = [];
        if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
          subChapters = _processChaptersRecursively(chapter.SubChapters!, 0);
        }

        if (subChapters.isNotEmpty) {
          PureLogger.debug('处理子章节: ${subChapters.length}');
        }

        return EpubChapter(
          id: title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_'),
          title: title,
          content: content,
          href: '',
          order: 0,
          subChapters: subChapters,
        );
      }).toList();

      PureLogger.debug('处理章节完成: ${chapters.length}章节');

      // 处理资源
      final resources = _processResourcesFromEpubx(epubBook);
      PureLogger.debug('处理资源完成: ${resources.length}资源');

      // 查找封面
      final coverImage = _findCoverImageFromEpubx(epubBook, resources);

      final result = EpubBook(
        title: title,
        author: author,
        identifier: identifier,
        chapters: chapters,
        resources: resources,
        coverImage: coverImage,
      );

      PureLogger.info('EPUB解析完成: ${chapters.length}章节, ${resources.length}资源');
      return result;
    } catch (e, stackTrace) {
      PureLogger.error('解析EPUB字节数据失败', e);
      _logStackTrace(stackTrace);
      rethrow;
    }
  }

  /// 从epubx对象处理章节
  static Future<List<EpubChapter>> _processChaptersFromEpubx(
    epubx.EpubBook epubBook,
  ) async {
    try {
      final chapters = <EpubChapter>[];

      // 获取章节列表
      final htmlFiles = epubBook.Content?.Html ?? {};
      final readingOrder = epubBook.Schema?.Package?.Spine?.Items ?? [];

      PureLogger.debug(
        '开始处理章节，HTML文件数: ${htmlFiles.length}, 阅读顺序: ${readingOrder.length}',
      );

      int order = 0;
      for (final spineItem in readingOrder) {
        try {
          final idRef = spineItem.IdRef;
          if (idRef == null) continue;

          // 查找对应的manifest项目
          final manifestItem = epubBook.Schema?.Package?.Manifest?.Items
              ?.where((item) => item.Id == idRef)
              .firstOrNull;

          if (manifestItem == null) {
            PureLogger.warning('未找到manifest项目: $idRef');
            continue;
          }

          final href = manifestItem.Href;
          if (href == null) continue;

          // 查找HTML内容
          final htmlContent = htmlFiles[href];
          if (htmlContent == null) {
            PureLogger.warning('未找到HTML内容: $href');
            continue;
          }

          // 处理章节内容
          final processedContent = await _processChapterContent(
            htmlContent.Content ?? '',
            epubBook,
          );

          // 提取章节标题
          final chapterTitle = _extractChapterTitle(
            htmlContent.Content ?? '',
            href,
            order + 1,
          );

          chapters.add(
            EpubChapter(
              id: idRef,
              title: chapterTitle,
              content: processedContent,
              href: href,
              order: order,
            ),
          );

          PureLogger.debug(
            '处理章节完成: $chapterTitle (${processedContent.length} 字符)',
          );
        } catch (e) {
          PureLogger.error('处理章节失败: ${spineItem.IdRef}', e);
          // 创建空章节以保持顺序
          chapters.add(
            EpubChapter(
              id: spineItem.IdRef ?? 'unknown',
              title: 'Chapter ${order + 1} (Error)',
              content: '<p>章节内容加载失败</p>',
              href: '',
              order: order,
            ),
          );
        }
        order++;
      }

      PureLogger.info('章节处理完成: ${chapters.length}/$order');
      return chapters;
    } catch (e) {
      PureLogger.error('处理章节列表失败', e);
      return [];
    }
  }

  /// 处理章节内容
  static Future<String> _processChapterContent(
    String htmlContent,
    epubx.EpubBook epubBook,
  ) async {
    try {
      if (htmlContent.isEmpty) {
        PureLogger.warning('章节内容为空');
        return '';
      }

      PureLogger.debug('处理章节内容: ${htmlContent.length} 字符');

      final doc = html_parser.parse(htmlContent);

      // 移除不需要的元素
      final removedElements = <String>[];
      doc.querySelectorAll('script, style, meta, link').forEach((element) {
        removedElements.add(element.localName ?? 'unknown');
        element.remove();
      });

      if (removedElements.isNotEmpty) {
        PureLogger.debug('移除元素: ${removedElements.join(', ')}');
      }

      // 处理图片链接
      int processedImages = 0;
      doc.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        if (src != null) {
          // 查找图片资源
          final imageContent = epubBook.Content?.Images?[src];
          if (imageContent != null) {
            final mimeType = _getMimeTypeFromExtension(src);
            final base64Data = _encodeToBase64(imageContent.Content ?? []);
            img.attributes['src'] = 'data:$mimeType;base64,$base64Data';
            processedImages++;
          }
        }
      });

      if (processedImages > 0) {
        PureLogger.debug('处理图片数量: $processedImages');
      }

      // 处理内部链接
      int processedLinks = 0;
      doc.querySelectorAll('a').forEach((link) {
        final linkHref = link.attributes['href'];
        if (linkHref != null && !linkHref.startsWith('http')) {
          link.attributes['data-internal'] = 'true';
          processedLinks++;
        }
      });

      if (processedLinks > 0) {
        PureLogger.debug('处理内部链接数量: $processedLinks');
      }

      // 获取处理后的内容
      final body = doc.querySelector('body');
      String result;

      if (body != null) {
        result = body.innerHtml ?? '';
        PureLogger.debug('使用 body.innerHtml，长度: ${result.length}');
      } else {
        doc.querySelectorAll('html, head').forEach((element) {
          element.remove();
        });
        result = doc.outerHtml ?? '';
        PureLogger.debug('使用 doc.outerHtml，长度: ${result.length}');
      }

      if (result.isEmpty) {
        PureLogger.warning('章节内容处理后为空');
      }

      return result;
    } catch (e) {
      PureLogger.error('处理章节内容失败', e);
      return '<p>内容处理失败</p>';
    }
  }

  /// 从epubx对象处理资源
  static Map<String, String> _processResourcesFromEpubx(
    epubx.EpubBook epubBook,
  ) {
    try {
      final resources = <String, String>{};
      int processedCount = 0;

      // 处理图片资源
      final images = epubBook.Content?.Images ?? {};
      for (final entry in images.entries) {
        final fileName = entry.key;
        final imageContent = entry.value;

        if (imageContent.Content != null) {
          final mimeType = _getMimeTypeFromExtension(fileName);
          final base64Data = _encodeToBase64(imageContent.Content!);
          resources[fileName] = 'data:$mimeType;base64,$base64Data';
          processedCount++;
        }
      }

      // 处理CSS资源
      final css = epubBook.Content?.Css ?? {};
      for (final entry in css.entries) {
        final fileName = entry.key;
        final cssContent = entry.value;

        if (cssContent.Content != null) {
          // CSS内容直接存储为字符串
          resources[fileName] = cssContent.Content.toString();
          processedCount++;
        }
      }

      // 处理字体资源
      final fonts = epubBook.Content?.Fonts ?? {};
      for (final entry in fonts.entries) {
        final fileName = entry.key;
        final fontContent = entry.value;

        if (fontContent.Content != null) {
          final mimeType = _getMimeTypeFromExtension(fileName);
          final base64Data = _encodeToBase64(fontContent.Content!);
          resources[fileName] = 'data:$mimeType;base64,$base64Data';
          processedCount++;
        }
      }

      PureLogger.debug('资源处理完成: $processedCount 个资源');
      return resources;
    } catch (e) {
      PureLogger.error('处理资源失败', e);
      return {};
    }
  }

  /// 从epubx对象查找封面图片
  static String? _findCoverImageFromEpubx(
    epubx.EpubBook epubBook,
    Map<String, String> resources,
  ) {
    try {
      // 方法1: 使用epubx的封面获取功能
      try {
        PureLogger.debug('开始获取封面图片');
        final coverImageContent = epubBook.CoverImage;
        if (coverImageContent != null) {
          PureLogger.debug('封面图片存在，开始转换');
          final mimeType = 'image/jpeg'; // 默认MIME类型
          // 将Image转换为字节数组
          final bytes = coverImageContent.getBytes();
          PureLogger.debug('获取字节数组完成，大小: ${bytes.length}');
          final base64Data = _encodeToBase64(bytes);
          PureLogger.debug('Base64编码完成');
          return 'data:$mimeType;base64,$base64Data';
        }
        PureLogger.debug('封面图片为空');
      } catch (e) {
        PureLogger.debug('获取epubx封面失败: $e');
      }

      PureLogger.warning('未找到封面图片');
      return null;
    } catch (e) {
      PureLogger.error('查找封面图片失败', e);
      return null;
    }
  }

  /// 提取章节标题
  static String _extractChapterTitle(
    String htmlContent,
    String href,
    int chapterNumber,
  ) {
    try {
      if (htmlContent.isEmpty) {
        return 'Chapter $chapterNumber';
      }

      final doc = html_parser.parse(htmlContent);

      // 尝试多种标题提取策略
      // 1. 查找标题标签 (h1-h6)
      for (final tag in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
        final titleElement = doc.querySelector(tag);
        if (titleElement != null && titleElement.text.trim().isNotEmpty) {
          return _cleanTitle(titleElement.text.trim());
        }
      }

      // 2. 查找title标签
      final titleElement = doc.querySelector('title');
      if (titleElement != null && titleElement.text.trim().isNotEmpty) {
        return _cleanTitle(titleElement.text.trim());
      }

      // 3. 查找具有特定class的元素
      final classSelectors = [
        '.chapter-title',
        '.title',
        '.chapter-heading',
        '.chapter-name',
        '.heading',
        '.section-title',
      ];
      for (final selector in classSelectors) {
        final element = doc.querySelector(selector);
        if (element != null && element.text.trim().isNotEmpty) {
          return _cleanTitle(element.text.trim());
        }
      }

      // 4. 查找第一个粗体文本作为标题
      final boldElement = doc.querySelector('b, strong');
      if (boldElement != null && boldElement.text.trim().isNotEmpty) {
        final text = boldElement.text.trim();
        if (text.length < 100) {
          return _cleanTitle(text);
        }
      }

      // 5. 从文件名提取标题
      final fileName = href
          .split('/')
          .last
          .replaceAll('.xhtml', '')
          .replaceAll('.html', '');
      if (fileName.isNotEmpty && fileName != 'index' && fileName != 'content') {
        return _cleanTitle(fileName.replaceAll(RegExp(r'[_-]'), ' '));
      }

      return 'Chapter $chapterNumber';
    } catch (e) {
      PureLogger.error('提取章节标题失败: $href', e);
      return 'Chapter $chapterNumber';
    }
  }

  /// 清理标题文本
  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[0-9]+\.?\s*'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
  }

  /// 根据文件扩展名获取MIME类型
  static String _getMimeTypeFromExtension(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.webp':
        return 'image/webp';
      case '.ttf':
        return 'font/ttf';
      case '.otf':
        return 'font/otf';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.css':
        return 'text/css';
      default:
        return 'application/octet-stream';
    }
  }

  /// Base64编码 - 使用Dart内置的高效实现
  static String _encodeToBase64(List<int> bytes) {
    return base64.encode(bytes);
  }

  /// 递归处理章节和子章节
  static List<EpubChapter> _processChaptersRecursively(
    List<epubx.EpubChapter> chapters,
    int startOrder,
  ) {
    final result = <EpubChapter>[];
    int order = startOrder;

    for (final chapter in chapters) {
      try {
        // 处理当前章节
        String title = chapter.Title ?? 'Chapter ${order + 1}';
        String content = chapter.HtmlContent ?? '';

        // 递归处理子章节
        List<EpubChapter> subChapters = [];
        if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
          subChapters = _processChaptersRecursively(chapter.SubChapters!, 0);
        }

        result.add(
          EpubChapter(
            id: 'chapter_$order',
            title: title,
            content: content,
            href: chapter.Anchor ?? '',
            order: order,
            subChapters: subChapters,
          ),
        );

        order++;
      } catch (e) {
        PureLogger.error('处理章节失败: ${chapter.Title ?? 'Unknown'}', e);
      }
    }

    return result;
  }

  /// 记录堆栈跟踪
  static void _logStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    for (int i = 0; i < lines.length && i < 10; i++) {
      PureLogger.debug('Stack[$i]: ${lines[i]}');
    }
  }
}

/// EPUB解析异常
class EpubException implements Exception {
  final String message;
  const EpubException(this.message);

  @override
  String toString() => 'EpubException: $message';
}
