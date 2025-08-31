import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/epub_reader.dart';
import '../services/epub_parser.dart';
import '../models/epub_book.dart';
import '../theme/reading_theme.dart';

class ReaderPage extends StatefulWidget {
  final String bookPath;
  final String bookTitle;

  const ReaderPage({
    super.key,
    required this.bookPath,
    required this.bookTitle,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  EpubBook? _book;
  bool _isLoading = true;
  String? _errorMessage;
  ReadingSettings _settings = ReadingSettings();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final book = await EpubParser.parseEpubFile(widget.bookPath);

      if (mounted) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载书籍失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle, style: const TextStyle(fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载书籍...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBook, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_book == null) {
      return const Center(child: Text('未找到书籍内容'));
    }

    return EpubReader(
      book: _book!,
      initialSettings: _settings,
      onSettingsChanged: (settings) {
        setState(() {
          _settings = settings;
        });
      },
      onPositionChanged: (position) {
        // 这里可以保存阅读进度
        debugPrint('阅读位置: ${position.chapterIndex}, ${position.scrollOffset}');
      },
      onBookmarkAdded: (bookmark) {
        // 这里可以处理书签添加
        debugPrint('添加书签');
      },
    );
  }
}
