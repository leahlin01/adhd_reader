import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/epub_book.dart';
import '../services/bookmark_service.dart';
import '../theme/reading_theme.dart';
import '../theme/app_theme.dart';
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

  // 性能优化：缓存处理过的内容
  final Map<int, String> _processedContentCache = {};
  final Map<int, Widget> _chapterWidgetCache = {};

  // 性能优化：节流器
  Timer? _scrollThrottleTimer;
  Timer? _positionSaveTimer;

  // 性能优化：防抖器
  Timer? _controlsHideTimer;

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
    _scrollController.addListener(_onScrollThrottled);

    // 初始显示控制栏
    _fadeController.forward();

    // 预加载当前章节内容
    _preloadChapterContent(_currentChapterIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scrollThrottleTimer?.cancel();
    _positionSaveTimer?.cancel();
    _controlsHideTimer?.cancel();
    super.dispose();
  }

  // 性能优化：预加载章节内容
  void _preloadChapterContent(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < widget.book.chapters.length) {
      final chapter = widget.book.chapters[chapterIndex];
      final cacheKey = chapterIndex;

      if (!_processedContentCache.containsKey(cacheKey)) {
        // 异步处理内容，避免阻塞UI
        Future.microtask(() {
          final processedContent = _processChapterContent(chapter);
          if (mounted) {
            setState(() {
              _processedContentCache[cacheKey] = processedContent;
            });
          }
        });
      }
    }
  }

  // 性能优化：处理章节内容
  String _processChapterContent(EpubChapter chapter) {
    final content = _getChapterContentWithSubChapters(chapter);
    return BionicReading.convertHtmlToBionicReading(
      content,
      boldRatio: _settings.bionicBoldRatio,
    );
  }

  void _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks(
      widget.book.identifier,
    );
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
      });
    }
  }

  void _loadReadingPosition() async {
    final position = await BookmarkService.getReadingPosition(
      widget.book.identifier,
    );
    if (position != null && mounted) {
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

  // 性能优化：节流滚动监听
  void _onScrollThrottled() {
    _scrollThrottleTimer?.cancel();
    _scrollThrottleTimer = Timer(const Duration(milliseconds: 16), () {
      _onScroll();
    });
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final chapterProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;
    final totalProgress =
        (_currentChapterIndex + chapterProgress) / widget.book.chapters.length;

    final newProgress = totalProgress.clamp(0.0, 1.0);

    // 只有进度变化超过0.1%时才更新UI
    if ((newProgress - _readingProgress).abs() > 0.001) {
      setState(() {
        _readingProgress = newProgress;
      });
    }

    final position = ReadingPosition(
      chapterIndex: _currentChapterIndex,
      scrollOffset: _scrollController.offset,
      timestamp: DateTime.now(),
    );

    widget.onPositionChanged?.call(position);

    // 性能优化：防抖保存位置
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(milliseconds: 500), () {
      BookmarkService.saveReadingPosition(widget.book.identifier, position);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _fadeController.forward();
      _controlsHideTimer?.cancel();
    } else {
      _fadeController.reverse();
    }
  }

  // 性能优化：自动隐藏控制栏
  void _scheduleControlsHide() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 3), () {
      if (_showControls && mounted) {
        _toggleControls();
      }
    });
  }

  void _onSettingsChanged(ReadingSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged?.call(newSettings);

    // 清除缓存，因为设置改变了
    _processedContentCache.clear();
    _chapterWidgetCache.clear();

    // 重新处理当前章节
    _preloadChapterContent(_currentChapterIndex);
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书签已添加'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _goToChapter(int index) {
    if (index >= 0 && index < widget.book.chapters.length) {
      setState(() {
        _currentChapterIndex = index;
      });
      _scrollController.jumpTo(0);

      // 预加载相邻章节
      _preloadChapterContent(index - 1);
      _preloadChapterContent(index + 1);
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
    // 添加调试信息和错误处理
    print('目录按钮被点击了');
    print('书籍章节数量: ${widget.book.chapters.length}');

    if (widget.book.chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('书籍没有章节内容')));
      return;
    }

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildTableOfContents(),
      );
    } catch (e) {
      print('显示目录时出错: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('显示目录失败: $e')));
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildSettingsPanel(setModalState),
      ),
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
    final cacheKey = _currentChapterIndex;

    // 检查缓存
    if (_chapterWidgetCache.containsKey(cacheKey)) {
      return _chapterWidgetCache[cacheKey]!;
    }

    final content =
        _processedContentCache[cacheKey] ??
        _processChapterContent(currentChapter);

    final chapterWidget = SingleChildScrollView(
      // 重命名变量避免冲突
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
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
                fontFamily: _settings.fontFamily, // 使用阅读设置中的字体
              ),
            ),
          ),
          // 章节内容 - 使用RepaintBoundary优化重绘
          RepaintBoundary(
            child: Html(
              data: content,
              style: {
                "body": Style(
                  fontSize: FontSize(_settings.fontSize),
                  color: themeData.textColor,
                  lineHeight: LineHeight(_settings.lineHeight),
                  fontFamily: _settings.fontFamily, // 使用阅读设置中的字体
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

    // 缓存widget
    _chapterWidgetCache[cacheKey] = chapterWidget; // 使用重命名后的变量
    return chapterWidget; // 使用重命名后的变量
  }

  Widget _buildTopToolbar() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 左边：返回按钮
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: themeData.textColor,
                    size: 20,
                  ),
                ),
              ),

              // 中间：书名（超出省略）
              Expanded(
                child: Center(
                  child: Text(
                    widget.book.title,
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.primaryFontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 右边：目录按钮
              GestureDetector(
                onTap: _showTableOfContents,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.menu, color: themeData.textColor, size: 20),
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
    final currentChapter = widget.book.chapters[_currentChapterIndex];
    final progressPercentage = (_readingProgress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 0,
          ),
          child: Column(
            children: [
              // 第一行：章节信息和进度百分比
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：章节标题
                  Expanded(
                    child: Text(
                      currentChapter.title.isNotEmpty
                          ? currentChapter.title
                          : 'Chapter ${_currentChapterIndex + 1}',
                      style: TextStyle(
                        color: themeData.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        // 暂时移除 fontFamily，使用系统默认字体
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 40),
                  // 右侧：进度百分比
                  Text(
                    '$progressPercentage%',
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      // 暂时移除 fontFamily，使用系统默认字体
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 第二行：进度条
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.black,
                        overlayColor: Colors.black.withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _readingProgress,
                        onChanged: _onProgressChanged,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第三行：导航控制
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 左侧：上一章按钮
                  GestureDetector(
                    onTap: _currentChapterIndex > 0 ? _previousChapter : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.chevron_left,
                        color: _currentChapterIndex > 0
                            ? themeData.textColor.withOpacity(0.7)
                            : themeData.textColor.withOpacity(0.3),
                        size: 24,
                      ),
                    ),
                  ),
                  // 中间：字体设置按钮
                  GestureDetector(
                    onTap: _showSettings,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          color: themeData.textColor.withOpacity(0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          // 暂时移除 fontFamily，使用系统默认字体
                        ),
                      ),
                    ),
                  ),
                  // 右侧：下一章按钮
                  GestureDetector(
                    onTap:
                        _currentChapterIndex < widget.book.chapters.length - 1
                        ? _nextChapter
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.chevron_right,
                        color:
                            _currentChapterIndex <
                                widget.book.chapters.length - 1
                            ? themeData.textColor.withOpacity(0.7)
                            : themeData.textColor.withOpacity(0.3),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableOfContents() {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

    // 添加调试信息
    print('构建目录，章节数量: ${widget.book.chapters.length}');
    print('当前章节索引: $_currentChapterIndex');

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
                  'Index',
                  style: TextStyle(
                    color: themeData.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFontFamily, // 使用项目约定的字体
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
            child: widget.book.chapters.isEmpty
                ? Center(
                    child: Text(
                      'None',
                      style: TextStyle(
                        color: themeData.textColor.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: AppTheme.primaryFontFamily,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.book.chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = widget.book.chapters[index];
                      final isCurrentChapter = index == _currentChapterIndex;

                      return ListTile(
                        title: Text(
                          chapter.title.isNotEmpty
                              ? chapter.title
                              : 'Chapter ${index + 1}',
                          style: TextStyle(
                            color: isCurrentChapter
                                ? themeData.primaryColor
                                : themeData.textColor,
                            fontWeight: isCurrentChapter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFamily: AppTheme.primaryFontFamily, // 使用项目约定的字体
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

  Widget _buildSettingsPanel(StateSetter setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFontFamily,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // 设置选项
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 字体大小设置
                  _buildSettingSection(
                    title: 'Font Size',
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _decreaseFontSize();
                            setModalState(() {});
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _settings.fontSize.toDouble(),
                            min: 12,
                            max: 24,
                            divisions: 12,
                            label: _settings.fontSize.round().toString(),
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              _onSettingsChanged(
                                _settings.copyWith(fontSize: value),
                              );
                              setModalState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _increaseFontSize();
                            setModalState(() {});
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 行间距设置
                  _buildSettingSection(
                    title: 'Line Height',
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_settings.lineHeight > 1.0) {
                              _onSettingsChanged(
                                _settings.copyWith(
                                  lineHeight: _settings.lineHeight - 0.1,
                                ),
                              );
                              setModalState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _settings.lineHeight,
                            min: 1.0,
                            max: 2.0,
                            divisions: 10,
                            label: _settings.lineHeight.toStringAsFixed(1),
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              _onSettingsChanged(
                                _settings.copyWith(lineHeight: value),
                              );
                              setModalState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_settings.lineHeight < 2.0) {
                              _onSettingsChanged(
                                _settings.copyWith(
                                  lineHeight: _settings.lineHeight + 0.1,
                                ),
                              );
                              setModalState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 页边距设置
                  _buildSettingSection(
                    title: 'Page Margin',
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_settings.pageMargin > 8.0) {
                              _onSettingsChanged(
                                _settings.copyWith(
                                  pageMargin: _settings.pageMargin - 4.0,
                                ),
                              );
                              setModalState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _settings.pageMargin,
                            min: 8.0,
                            max: 32.0,
                            divisions: 6,
                            label: _settings.pageMargin.round().toString(),
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              _onSettingsChanged(
                                _settings.copyWith(pageMargin: value),
                              );
                              setModalState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_settings.pageMargin < 32.0) {
                              _onSettingsChanged(
                                _settings.copyWith(
                                  pageMargin: _settings.pageMargin + 4.0,
                                ),
                              );
                              setModalState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 主题设置
                  _buildSettingSection(
                    title: 'Theme',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ReadingTheme.values.map((theme) {
                        final isSelected = _settings.theme == theme;
                        final themeData = ReadingThemeData.getTheme(theme);

                        return GestureDetector(
                          onTap: () {
                            _onSettingsChanged(
                              _settings.copyWith(theme: theme),
                            );
                            setModalState(() {});
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: themeData.backgroundColor,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
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
                                  fontFamily: AppTheme.primaryFontFamily,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ReadingThemeData.getTheme(_settings.theme);

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
              onTap: () {
                _toggleControls();
                if (_showControls) {
                  _scheduleControlsHide();
                }
              },
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
