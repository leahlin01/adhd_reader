import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/book_service.dart';
import '../services/text_reader_service.dart';

// 移除阅读模式枚举，只支持滚动阅读
enum TextDisplayMode { bionic, html, plain }

class Bookmark {
  final String id;
  final String bookId;
  final int chapterIndex;
  final int pageIndex;
  final String title;
  final String preview;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.pageIndex,
    required this.title,
    required this.preview,
    required this.createdAt,
  });
}

class ReaderPage extends StatefulWidget {
  final Book book;

  const ReaderPage({super.key, required this.book});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  // Reader settings
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  bool _showToolbar = true;
  // 移除阅读模式变量，只支持滚动阅读
  TextDisplayMode _textDisplayMode = TextDisplayMode.bionic;

  // Content state
  List<Chapter> _chapters = [];
  int _currentChapterIndex = 0;
  String _errorMessage = '';
  bool _isLoading = true;

  // 移除分页模式相关变量

  // Scrolling mode
  final ScrollController _scrollController = ScrollController();

  // Bookmarks
  List<Bookmark> _bookmarks = [];
  bool _isCurrentPositionBookmarked = false;

  double get _progress {
    if (_chapters.isEmpty) return 0.0;
    return (_currentChapterIndex + 1) / _chapters.length;
  }

  @override
  void initState() {
    super.initState();
    _loadBookContent();
    _loadBookmarks();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    _saveProgress();
    _updateBookmarkStatus();
  }

  Future<void> _loadBookContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final chapters = await TextReaderService.instance.readBookChapters(
        widget.book.filePath,
        widget.book.fileType,
      );

      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });

      // Calculate starting position based on book progress
      final startingChapter = (widget.book.progress * chapters.length).floor();
      _currentChapterIndex = startingChapter.clamp(0, chapters.length - 1);

      _updateBookmarkStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load book content: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    // TODO: Implement bookmark loading from storage
    // For now, initialize empty list
    setState(() {
      _bookmarks = [];
    });
  }

  void _updateBookmarkStatus() {
    final isBookmarked = _bookmarks.any((bookmark) =>
        bookmark.chapterIndex == _currentChapterIndex);
    
    if (_isCurrentPositionBookmarked != isBookmarked) {
      setState(() {
        _isCurrentPositionBookmarked = isBookmarked;
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
          : _buildScrollingMode(),
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
              onPressed: _loadBookContent,
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



  Widget _buildScrollingMode() {
    return GestureDetector(
      onTap: _toggleToolbar,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            _previousChapter();
          } else if (details.primaryVelocity! < 0) {
            _nextChapter();
          }
        }
      },
      child: Stack(
        children: [
          _buildScrollingContent(),
          if (_showToolbar) _buildTopToolbar(),
          if (_showToolbar) _buildBottomControlBar(),
        ],
      ),
    );
  }



  Widget _buildScrollingContent() {
    if (_chapters.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    final currentChapter = _chapters[_currentChapterIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'by ${widget.book.author}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentChapter.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chapter ${_currentChapterIndex + 1} of ${_chapters.length} • ${(_progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextContent(_chapters[_currentChapterIndex].content, _currentChapterIndex),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(String content, int chapterIndex) {
    switch (_textDisplayMode) {
      case TextDisplayMode.html:
        return _buildHtmlContent(chapterIndex);
      case TextDisplayMode.plain:
        return _buildPlainText(content);
      case TextDisplayMode.bionic:
      default:
        return _buildBionicText(content);
    }
  }

  Widget _buildHtmlContent(int chapterIndex) {
    if (_chapters.isEmpty || chapterIndex >= _chapters.length) {
      return const Text('No content available');
    }

    final chapter = _chapters[chapterIndex];
    final htmlContent = chapter.htmlContent;

    if (htmlContent == null || htmlContent.trim().isEmpty) {
      return _buildBionicText(chapter.content);
    }

    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          fontSize: FontSize(_fontSize),
          lineHeight: LineHeight(_lineHeight),
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
        "p": Style(
          margin: Margins.only(bottom: 16),
          textAlign: TextAlign.justify,
        ),
        "h1": Style(
          fontSize: FontSize(_fontSize * 1.5),
          fontWeight: FontWeight.bold,
          margin: Margins.symmetric(vertical: 24),
        ),
        "h2": Style(
          fontSize: FontSize(_fontSize * 1.3),
          fontWeight: FontWeight.w600,
          margin: Margins.symmetric(vertical: 20),
        ),
        "h3": Style(
          fontSize: FontSize(_fontSize * 1.2),
          fontWeight: FontWeight.w600,
          margin: Margins.symmetric(vertical: 16),
        ),
        "strong": Style(fontWeight: FontWeight.bold),
        "em": Style(fontStyle: FontStyle.italic),
        "b": Style(fontWeight: FontWeight.bold),
        "i": Style(fontStyle: FontStyle.italic),
        "blockquote": Style(
          margin: Margins.all(16),
          padding: HtmlPaddings.all(16),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
      },
    );
  }

  Widget _buildPlainText(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildBionicText(String text) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final paragraphWidgets = <Widget>[];

    for (int p = 0; p < paragraphs.length; p++) {
      final paragraph = paragraphs[p].trim();
      if (paragraph.isEmpty) continue;

      final sentences = _splitIntoSentences(paragraph);
      final sentenceSpans = <InlineSpan>[];

      for (int s = 0; s < sentences.length; s++) {
        final sentence = sentences[s];
        if (sentence.trim().isEmpty) continue;

        final wordSpans = _processWordsForBionic(sentence);
        sentenceSpans.addAll(wordSpans);

        if (s < sentences.length - 1) {
          sentenceSpans.add(TextSpan(
            text: ' ',
            style: _getTextStyle(false),
          ));
        }
      }

      paragraphWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: p < paragraphs.length - 1 ? 16.0 : 0.0),
          child: RichText(
            text: TextSpan(
              children: sentenceSpans,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphWidgets,
    );
  }

  List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'[.!?]+\s+')).where((s) => s.trim().isNotEmpty).toList();
  }

  List<InlineSpan> _processWordsForBionic(String sentence) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r"(\s+|[\w'\-]+|[^\w\s'\-]+)");
    final matches = pattern.allMatches(sentence);

    for (final match in matches) {
      final part = match.group(0)!;
      
      if (RegExp(r'^\s+$').hasMatch(part)) {
        spans.add(TextSpan(text: part, style: _getTextStyle(false)));
        continue;
      }

      if (RegExp(r"\w").hasMatch(part)) {
        spans.addAll(_createBionicWord(part));
      } else {
        spans.add(TextSpan(text: part, style: _getTextStyle(false)));
      }
    }

    return spans;
  }

  List<InlineSpan> _createBionicWord(String word) {
    final wordMatch = RegExp(r"([^\w]*)(\w+)([^\w]*)").firstMatch(word);
    
    if (wordMatch == null) {
      return [TextSpan(text: word, style: _getTextStyle(false))];
    }

    final prefix = wordMatch.group(1) ?? '';
    final coreWord = wordMatch.group(2) ?? '';
    final suffix = wordMatch.group(3) ?? '';

    if (coreWord.isEmpty) {
      return [TextSpan(text: word, style: _getTextStyle(false))];
    }

    final spans = <InlineSpan>[];

    if (prefix.isNotEmpty) {
      spans.add(TextSpan(text: prefix, style: _getTextStyle(false)));
    }

    final boldLength = _calculateBoldLength(coreWord.length);
    final boldPart = coreWord.substring(0, boldLength);
    final regularPart = coreWord.substring(boldLength);

    spans.add(TextSpan(text: boldPart, style: _getTextStyle(true)));

    if (regularPart.isNotEmpty) {
      spans.add(TextSpan(text: regularPart, style: _getTextStyle(false)));
    }

    if (suffix.isNotEmpty) {
      spans.add(TextSpan(text: suffix, style: _getTextStyle(false)));
    }

    return spans;
  }

  int _calculateBoldLength(int wordLength) {
    if (wordLength <= 1) return 1;
    if (wordLength <= 2) return 1;
    if (wordLength <= 4) return 2;
    if (wordLength <= 6) return 3;
    if (wordLength <= 8) return 3;
    return (wordLength * 0.4).ceil().clamp(1, wordLength - 1);
  }

  TextStyle _getTextStyle(bool isBold) {
    return TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      fontSize: _fontSize,
      height: _lineHeight,
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
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showTableOfContents,
                  icon: const Icon(Icons.list),
                  tooltip: 'Table of Contents',
                ),
                IconButton(
                  onPressed: _showBookmarks,
                  icon: const Icon(Icons.bookmarks),
                  tooltip: 'Bookmarks',
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
                  onPressed: _toggleBookmark,
                  icon: Icon(
                    _isCurrentPositionBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isCurrentPositionBookmarked
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: 'Bookmark',
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
                  onPressed: _previousChapter,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Chapter',
                ),
                IconButton(
                  onPressed: _nextChapter,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Chapter',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 移除分页生成方法

  void _toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
  }

  void _toggleBookmark() {
    if (_isCurrentPositionBookmarked) {
      _removeBookmark();
    } else {
      _addBookmark();
    }
  }

  void _addBookmark() {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      chapterIndex: _currentChapterIndex,
      pageIndex: 0, // 滚动模式下不需要页面索引
      title: _chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : 'Bookmark',
      preview: _getBookmarkPreview(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _bookmarks.add(bookmark);
      _isCurrentPositionBookmarked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeBookmark() {
    _bookmarks.removeWhere((bookmark) =>
        bookmark.chapterIndex == _currentChapterIndex);

    setState(() {
      _isCurrentPositionBookmarked = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getBookmarkPreview() {
    if (_chapters.isNotEmpty) {
      final content = _chapters[_currentChapterIndex].content;
      return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }
    return '';
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 1).clamp(14.0, 24.0);
    });
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 1).clamp(14.0, 24.0);
    });
  }

  // 移除分页相关方法

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _saveProgress();
      _updateBookmarkStatus();
      _showPageChangeSnackBar('Previous chapter', Icons.chevron_left);

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      setState(() {
        _currentChapterIndex++;
      });
      _saveProgress();
      _updateBookmarkStatus();
      _showPageChangeSnackBar('Next chapter', Icons.chevron_right);

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showPageChangeSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveProgress() async {
    final newProgress = _progress;
    await BookService.instance.updateBookProgress(widget.book.id, newProgress);
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table of Contents',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final progress = (index + 1) / _chapters.length;
                    return _buildChapterItem(chapter.title, index, progress);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(String title, int chapterIndex, double position) {
    return ListTile(
      title: Text(title),
      trailing: Text('${(position * 100).toInt()}%'),
      selected: chapterIndex == _currentChapterIndex,
      onTap: () {
        setState(() {
          _currentChapterIndex = chapterIndex.clamp(0, _chapters.length - 1);
        });
        _saveProgress();
        _updateBookmarkStatus();
        Navigator.of(context).pop();
      },
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bookmarks',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (_bookmarks.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No bookmarks yet'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks[index];
                      return _buildBookmarkItem(bookmark);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark) {
    return ListTile(
      title: Text(bookmark.title),
      subtitle: Text(
        bookmark.preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          setState(() {
            _bookmarks.remove(bookmark);
            _updateBookmarkStatus();
          });
        },
      ),
      onTap: () {
        setState(() {
          _currentChapterIndex = bookmark.chapterIndex;
        });
        _saveProgress();
        _updateBookmarkStatus();
        Navigator.of(context).pop();
      },
    );
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
                subtitle: Text('${_fontSize.toInt()}px'),
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
                title: const Text('Line Height'),
                subtitle: Text(_lineHeight.toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _lineHeight = (_lineHeight - 0.1).clamp(1.2, 2.0);
                        });
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _lineHeight = (_lineHeight + 0.1).clamp(1.2, 2.0);
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Text Display Mode'),
                subtitle: Text(
                  _textDisplayMode == TextDisplayMode.bionic
                      ? 'Bionic Reading (Enhanced Focus)'
                      : _textDisplayMode == TextDisplayMode.html
                      ? 'Original HTML Formatting'
                      : 'Plain Text',
                ),
                trailing: PopupMenuButton<TextDisplayMode>(
                  initialValue: _textDisplayMode,
                  onSelected: (TextDisplayMode value) {
                    setState(() {
                      _textDisplayMode = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<TextDisplayMode>>[
                    const PopupMenuItem<TextDisplayMode>(
                      value: TextDisplayMode.bionic,
                      child: Text('Bionic Reading'),
                    ),
                    const PopupMenuItem<TextDisplayMode>(
                      value: TextDisplayMode.html,
                      child: Text('Original HTML'),
                    ),
                    const PopupMenuItem<TextDisplayMode>(
                      value: TextDisplayMode.plain,
                      child: Text('Plain Text'),
                    ),
                  ],
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