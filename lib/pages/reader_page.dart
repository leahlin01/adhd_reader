import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../services/book_service.dart';

class ReaderPage extends StatefulWidget {
  final Book book;

  const ReaderPage({super.key, required this.book});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final epubController = EpubController();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showToolbar = true;
  double _progress = 0.0;
  List<EpubChapter> _chapters = [];
  bool _showChapters = false;

  // Reader settings
  String _currentChapter = '';

  @override
  void initState() {
    super.initState();
    _initializeEpubReader();
  }

  Future<void> _initializeEpubReader() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 检查文件是否为EPUB格式
      if (!widget.book.filePath.toLowerCase().endsWith('.epub')) {
        setState(() {
          _errorMessage =
              'This file is not an EPUB format. flutter_epub_viewer only supports EPUB files.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize EPUB reader: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildEpubReader(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Unable to Load Book',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeEpubReader,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpubReader() {
    return GestureDetector(
      onTap: _toggleToolbar,
      child: Stack(
        children: [
          EpubViewer(
            epubSource: EpubSource.fromFile(File(widget.book.filePath)),
            epubController: epubController,
            displaySettings: EpubDisplaySettings(
              flow: EpubFlow.paginated,
              theme: EpubTheme.light(),
            ),
            onChaptersLoaded: (chapters) {
              setState(() {
                _chapters = chapters;
                _isLoading = false;
              });
            },
            onEpubLoaded: () async {
              print('Epub loaded');
            },
            onRelocated: (value) {
              setState(() {
                _progress = value.progress;
              });
            },
          ),
          if (_showToolbar) _buildTopToolbar(),
          if (_showToolbar) _buildBottomControlBar(),
          if (_showChapters) _buildChaptersList(),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_currentChapter.isNotEmpty)
                        Text(
                          _currentChapter,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleChaptersList,
                  icon: const Icon(Icons.list),
                  tooltip: 'Table of Contents',
                ),
                IconButton(
                  onPressed: _showReaderSettings,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Reader Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Page',
                ),
                IconButton(
                  onPressed: _decreaseFontSize,
                  icon: const Icon(Icons.text_decrease),
                  tooltip: 'Decrease Font Size',
                ),
                IconButton(
                  onPressed: _increaseFontSize,
                  icon: const Icon(Icons.text_increase),
                  tooltip: 'Increase Font Size',
                ),
                IconButton(
                  onPressed: _nextPage,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Page',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
  }

  void _previousPage() {
    // flutter_epub_viewer 可能使用不同的导航方法
    // 需要根据实际 API 文档调整
    try {
      epubController.prev();
    } catch (e) {
      // 如果方法不存在，暂时留空或使用其他方式
      print('Previous page navigation not available: $e');
    }
  }

  void _nextPage() {
    // flutter_epub_viewer 可能使用不同的导航方法
    // 需要根据实际 API 文档调整
    try {
      epubController.next();
    } catch (e) {
      // 如果方法不存在，暂时留空或使用其他方式
      print('Next page navigation not available: $e');
    }
  }

  void _decreaseFontSize() {
    // 需要根据实际的 flutter_epub_viewer API 实现
    // epubController.setFontSize(fontSize - 2);
  }

  void _increaseFontSize() {
    // 需要根据实际的 flutter_epub_viewer API 实现
    // epubController.setFontSize(fontSize + 2);
  }

  Future<void> _loadBookProgress() async {
    // 从存储中加载阅读进度
    // 这里可以根据需要实现进度恢复功能
  }

  Future<void> _saveProgress() async {
    // 保存当前阅读进度
    await BookService.instance.updateBookProgress(widget.book.id, _progress);
  }

  void _toggleChaptersList() {
    setState(() {
      _showChapters = !_showChapters;
    });
  }

  Widget _buildChaptersList() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: GestureDetector(
          onTap: () => setState(() => _showChapters = false),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {}, // 防止点击章节列表时关闭
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Menu',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _showChapters = false),
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _chapters.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_outlined,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading...',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _chapters.length,
                              itemBuilder: (context, index) {
                                final chapter = _chapters[index];
                                return _buildChapterItem(chapter, index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(EpubChapter chapter, int index) {
    final isCurrentChapter = _currentChapter == chapter.title;

    return InkWell(
      onTap: () => _navigateToChapter(chapter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentChapter
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: isCurrentChapter
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentChapter
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCurrentChapter
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 移除子章节显示，因为 EpubChapter 可能没有 subChapters 属性
                ],
              ),
            ),
            if (isCurrentChapter)
              Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToChapter(EpubChapter chapter) {
    try {
      // 使用 EpubController 导航到指定章节
      epubController.display(cfi: chapter.href);
      setState(() {
        _currentChapter = chapter.title ?? '';
        _showChapters = false;
      });
    } catch (e) {
      print('导航到章节失败: $e');
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法跳转到该章节: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showTableOfContents() {
    _toggleChaptersList();
  }

  void _showReaderSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reader Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Font Size'),
                subtitle: const Text('Font size adjustment'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _decreaseFontSize,
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: _increaseFontSize,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Theme'),
                subtitle: const Text('Light/Dark theme support'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    // 这里可以实现主题切换
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
