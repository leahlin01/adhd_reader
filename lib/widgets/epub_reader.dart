import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/epub_book.dart';
import '../services/bookmark_service.dart';
import '../theme/reading_theme.dart';
import 'reading_controls.dart';

class EpubReader extends StatefulWidget {
  final EpubBook book;
  final ReadingSettings initialSettings;
  final Function(ReadingSettings)? onSettingsChanged;
  final Function(ReadingPosition)? onPositionChanged;
  final Function(Bookmark)? onBookmarkAdded;

  const EpubReader({
    Key? key,
    required this.book,
    this.initialSettings = const ReadingSettings(),
    this.onSettingsChanged,
    this.onPositionChanged,
    this.onBookmarkAdded,
  }) : super(key: key);

  @override
  State<EpubReader> createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> with TickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  late ReadingSettings _settings;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentChapterIndex = 0;
  bool _showControls = false;
  List<Bookmark> _bookmarks = [];
  ReadingPosition? _lastPosition;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _pageController = PageController();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _loadBookmarks();
    _loadReadingPosition();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks(
      widget.book.identifier,
    );
    setState(() {
      _bookmarks = bookmarks;
    });
  }

  void _loadReadingPosition() async {
    final position = await BookmarkService.getReadingPosition(
      widget.book.identifier,
    );
    if (position != null) {
      setState(() {
        _currentChapterIndex = position.chapterIndex;
        _lastPosition = position;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(position.scrollOffset);
        }
      });
    }
  }

  void _onScroll() {
    final position = ReadingPosition(
      chapterIndex: _currentChapterIndex,
      scrollOffset: _scrollController.offset,
      timestamp: DateTime.now(),
    );

    widget.onPositionChanged?.call(position);
    BookmarkService.saveReadingPosition(widget.book.identifier, position);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _onSettingsChanged(ReadingSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged?.call(newSettings);
  }

  void _addBookmark() async {
    final bookmark = Bookmark(
      id: BookmarkService.generateId(),
      bookId: widget.book.identifier,
      chapterIndex: _currentChapterIndex,
      scrollOffset: _scrollController.offset,
      createdAt: DateTime.now(),
    );

    await BookmarkService.addBookmark(bookmark);
    _loadBookmarks();
    widget.onBookmarkAdded?.call(bookmark);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('书签已添加')));
  }

  void _goToChapter(int index) {
    if (index >= 0 && index < widget.book.chapters.length) {
      setState(() {
        _currentChapterIndex = index;
      });
      _scrollController.jumpTo(0);
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      _goToChapter(_currentChapterIndex - 1);
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < widget.book.chapters.length - 1) {
      _goToChapter(_currentChapterIndex + 1);
    }
  }

  /// 递归获取章节内容，包括所有子章节
  String _getChapterContentWithSubChapters(EpubChapter chapter) {
    StringBuffer content = StringBuffer();

    // 添加主章节内容
    content.write(chapter.content);

    // 递归添加子章节内容
    for (final subChapter in chapter.subChapters) {
      content.write('<div style="margin-top: 20px;">');
      content.write('<h3>${subChapter.title}</h3>');
      content.write(_getChapterContentWithSubChapters(subChapter));
      content.write('</div>');
    }

    return content.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ReadingThemeData.getTheme(_settings.theme);
    final currentChapter = widget.book.chapters[_currentChapterIndex];

    return Scaffold(
      backgroundColor: themeData.backgroundColor,
      body: Stack(
        children: [
          // 主要内容区域
          GestureDetector(
            onTap: _toggleControls,
            child: Container(
              color: themeData.backgroundColor,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(_settings.pageMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 章节标题
                    Padding(
                      padding: const EdgeInsets.only(top: 50, bottom: 20),
                      child: Text(
                        currentChapter.title,
                        style: TextStyle(
                          fontSize: _settings.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: themeData.textColor,
                          height: _settings.lineHeight,
                        ),
                      ),
                    ),
                    // 章节内容
                    Html(
                      data: _getChapterContentWithSubChapters(currentChapter),
                      style: {
                        "body": Style(
                          fontSize: FontSize(_settings.fontSize),
                          color: themeData.textColor,
                          lineHeight: LineHeight(_settings.lineHeight),
                          fontFamily: _settings.fontFamily,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "p": Style(margin: Margins.only(bottom: 16)),
                        "h1, h2, h3, h4, h5, h6": Style(
                          color: themeData.primaryColor,
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(top: 20, bottom: 10),
                        ),
                      },
                    ),
                    // 章节导航
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentChapterIndex > 0)
                            ElevatedButton.icon(
                              onPressed: _previousChapter,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('上一章'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            const SizedBox(),

                          if (_currentChapterIndex <
                              widget.book.chapters.length - 1)
                            ElevatedButton.icon(
                              onPressed: _nextChapter,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('下一章'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 控制面板
          if (_showControls)
            FadeTransition(
              opacity: _fadeAnimation,
              child: ReadingControls(
                book: widget.book,
                settings: _settings,
                currentChapterIndex: _currentChapterIndex,
                bookmarks: _bookmarks,
                onSettingsChanged: _onSettingsChanged,
                onChapterChanged: _goToChapter,
                onAddBookmark: _addBookmark,
                onClose: _toggleControls,
              ),
            ),
        ],
      ),
    );
  }
}
