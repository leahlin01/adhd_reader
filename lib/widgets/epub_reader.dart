import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/epub_book.dart';
import '../services/bookmark_service.dart';
import '../theme/reading_theme.dart';
import '../utils/bionic_reading.dart';

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
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentChapterIndex = 0;
  bool _showControls = true;
  List<Bookmark> _bookmarks = [];
  ReadingPosition? _lastPosition;
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _pageController = PageController();
    _scrollController = ScrollController();

    // 淡入淡出动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // 滑动动画控制器
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _loadBookmarks();
    _loadReadingPosition();
    _scrollController.addListener(_onScroll);

    // 初始显示控制栏
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
    // 节流处理，减少频繁的setState调用
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final chapterProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
      final totalProgress =
          (_currentChapterIndex + chapterProgress) /
          widget.book.chapters.length;

      final newProgress = totalProgress.clamp(0.0, 1.0);

      // 只有进度变化超过0.1%时才更新UI
      if ((newProgress - _readingProgress).abs() > 0.001) {
        setState(() {
          _readingProgress = newProgress;
        });
      }
    }

    final position = ReadingPosition(
      chapterIndex: _currentChapterIndex,
      scrollOffset: _scrollController.offset,
      timestamp: DateTime.now(),
    );

    widget.onPositionChanged?.call(position);

    // 异步保存位置，避免阻塞UI
    Future.microtask(() {
      BookmarkService.saveReadingPosition(widget.book.identifier, position);
    });
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('书签已添加'), duration: Duration(seconds: 2)),
    );
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

  void _onProgressChanged(double value) {
    final targetChapter = (value * widget.book.chapters.length).floor();
    final chapterProgress =
        (value * widget.book.chapters.length) - targetChapter;

    if (targetChapter != _currentChapterIndex) {
      _goToChapter(targetChapter);
    }

    // 跳转到章节内的相应位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetScroll = maxScroll * chapterProgress;
        _scrollController.jumpTo(targetScroll);
      }
    });
  }

  void _increaseFontSize() {
    if (_settings.fontSize < 24) {
      _onSettingsChanged(_settings.copyWith(fontSize: _settings.fontSize + 1));
    }
  }

  void _decreaseFontSize() {
    if (_settings.fontSize > 12) {
      _onSettingsChanged(_settings.copyWith(fontSize: _settings.fontSize - 1));
    }
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTableOfContents(),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsPanel(),
    );
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

  /// 构建优化的内容显示
  Widget _buildOptimizedContent() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);
    final currentChapter = widget.book.chapters[_currentChapterIndex];

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(), // 使用更流畅的滚动物理
      padding: EdgeInsets.only(
        left: _settings.pageMargin,
        right: _settings.pageMargin,
        top: 50,
        bottom: 50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 章节标题
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
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
          // 章节内容 - 使用RepaintBoundary优化重绘
          RepaintBoundary(
            child: Html(
              data: BionicReading.convertHtmlToBionicReading(
                _getChapterContentWithSubChapters(currentChapter),
                boldRatio: _settings.bionicBoldRatio,
              ),
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
                "b": Style(
                  fontWeight: FontWeight.bold,
                  color: themeData.textColor,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: themeData.backgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 第一行：设置按钮、目录按钮
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _showSettings,
                          icon: Icon(
                            Icons.settings,
                            color: themeData.primaryColor,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: _showTableOfContents,
                          icon: Icon(
                            Icons.menu,
                            color: themeData.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);
    final isBookmarked = _bookmarks.any(
      (b) =>
          b.chapterIndex == _currentChapterIndex &&
          (b.scrollOffset - _scrollController.offset).abs() < 100,
    );

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: themeData.backgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 书签按钮
              InkWell(
                onTap: _addBookmark,
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? themeData.primaryColor
                      : themeData.textColor.withOpacity(0.7),
                  size: 24,
                ),
              ),
              // 字体减小
              InkWell(
                onTap: _decreaseFontSize,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'A',
                      style: TextStyle(
                        color: themeData.textColor.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.remove,
                      color: themeData.textColor.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
              // 字体增大
              InkWell(
                onTap: _increaseFontSize,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'A',
                      style: TextStyle(
                        color: themeData.textColor.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.add,
                      color: themeData.textColor.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _currentChapterIndex > 0 ? _previousChapter : null,
                child: Icon(
                  Icons.arrow_back_ios,
                  color: _currentChapterIndex > 0
                      ? themeData.textColor.withOpacity(0.7)
                      : themeData.textColor.withOpacity(0.3),
                  size: 20,
                ),
              ),
              // 翻页按钮
              InkWell(
                onTap: _currentChapterIndex < widget.book.chapters.length - 1
                    ? _nextChapter
                    : null,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: _currentChapterIndex < widget.book.chapters.length - 1
                      ? themeData.textColor.withOpacity(0.7)
                      : themeData.textColor.withOpacity(0.3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableOfContents() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: themeData.textColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目录',
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: themeData.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // 章节列表
          Expanded(
            child: ListView.builder(
              itemCount: widget.book.chapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.book.chapters[index];
                final isCurrentChapter = index == _currentChapterIndex;

                return ListTile(
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: isCurrentChapter
                          ? themeData.primaryColor
                          : themeData.textColor,
                      fontWeight: isCurrentChapter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  leading: Container(
                    width: 4,
                    height: 20,
                    color: isCurrentChapter
                        ? themeData.primaryColor
                        : Colors.transparent,
                  ),
                  onTap: () {
                    _goToChapter(index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: themeData.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: themeData.textColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '阅读设置',
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: themeData.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // 设置选项
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '字体大小',
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _decreaseFontSize,
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: themeData.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _settings.fontSize.toDouble(),
                          min: 12,
                          max: 24,
                          divisions: 12,
                          label: _settings.fontSize.toString(),
                          onChanged: (value) {
                            _onSettingsChanged(
                              _settings.copyWith(fontSize: value),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _increaseFontSize,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: themeData.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '主题',
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ReadingTheme.values.map((theme) {
                      final isSelected = _settings.theme == theme;
                      final themeData = ReadingThemeData.getTheme(theme);

                      return GestureDetector(
                        onTap: () {
                          _onSettingsChanged(_settings.copyWith(theme: theme));
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: themeData.backgroundColor,
                            border: Border.all(
                              color: isSelected
                                  ? themeData.primaryColor
                                  : themeData.textColor.withOpacity(0.3),
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: themeData.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ReadingThemeData.getTheme(_settings.theme);
    final currentChapter = widget.book.chapters[_currentChapterIndex];

    return Scaffold(
      backgroundColor: themeData.backgroundColor,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            // 主要内容区域
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onHorizontalDragEnd: (details) {
                // 左右滑动翻页
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 0) {
                    // 向右滑动，上一章
                    _previousChapter();
                  } else if (details.primaryVelocity! < 0) {
                    // 向左滑动，下一章
                    _nextChapter();
                  }
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                color: themeData.backgroundColor,
                child: _buildOptimizedContent(),
              ),
            ),

            // 顶部工具栏
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTopToolbar(),
                ),
              ),

            // 底部控制栏
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBottomToolbar(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
