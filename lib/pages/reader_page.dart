import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../services/text_reader_service.dart';

enum ReadingMode { paging, scrolling }

class ReaderPage extends StatefulWidget {
  final Book book;

  const ReaderPage({super.key, required this.book});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  bool _showToolbar = true;
  bool _isBookmarked = false;
  bool _isLoading = true;
  ReadingMode _readingMode = ReadingMode.paging;

  List<String> _pages = [];
  int _currentPageIndex = 0;
  String _errorMessage = '';
  
  // For scrolling mode
  final ScrollController _scrollController = ScrollController();
  String _fullText = '';

  double get _progress {
    if (_readingMode == ReadingMode.paging) {
      if (_pages.isEmpty) return 0.0;
      return (_currentPageIndex + 1) / _pages.length;
    } else {
      // For scrolling mode, calculate progress based on scroll position
      if (!_scrollController.hasClients || _fullText.isEmpty) return 0.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll == 0) return 1.0;
      return (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBookContent();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (_readingMode == ReadingMode.scrolling) {
      // Save progress periodically while scrolling
      _saveProgress();
    }
  }

  Future<void> _loadBookContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final content = await TextReaderService.instance.readBookContent(
        widget.book.filePath,
        widget.book.fileType,
      );

      final sanitizedContent = TextReaderService.instance.sanitizeText(content);
      final pages = TextReaderService.instance.splitIntoPages(sanitizedContent);

      // Store full text for scrolling mode
      _fullText = sanitizedContent;

      // Calculate the starting page based on the book's progress
      final startingPage = (widget.book.progress * pages.length).floor();

      setState(() {
        _pages = pages;
        _currentPageIndex = startingPage.clamp(0, pages.length - 1);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load book content: ${e.toString()}';
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
          : _readingMode == ReadingMode.paging
          ? _buildPagingMode()
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

  Widget _buildPagingMode() {
    return GestureDetector(
      onTap: _toggleToolbar,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _previousPage();
        } else if (details.primaryVelocity! < 0) {
          _nextPage();
        }
      },
      child: Stack(
        children: [
          // Reading content
          _buildPagingContent(),

          // Top toolbar
          if (_showToolbar) _buildTopToolbar(),

          // Bottom control bar
          if (_showToolbar) _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildScrollingMode() {
    return GestureDetector(
      onTap: _toggleToolbar,
      child: Stack(
        children: [
          // Reading content
          _buildScrollingContent(),

          // Top toolbar
          if (_showToolbar) _buildTopToolbar(),

          // Bottom control bar
          if (_showToolbar) _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildPagingContent() {
    if (_pages.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book title and author
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
              // Page indicator
              Text(
                'Page ${_currentPageIndex + 1} of ${_pages.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Bionic reading text
              _buildBionicText(_pages[_currentPageIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBionicText(String text) {
    // Preserve original formatting by not trimming paragraphs
    final paragraphs = text.split('\n');
    final paragraphSpans = <InlineSpan>[];

    for (int p = 0; p < paragraphs.length; p++) {
      final paragraph = paragraphs[p];

      if (paragraph.isEmpty) {
        // Add line break for empty paragraphs
        paragraphSpans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Use a more precise regex to split while preserving all whitespace
      final parts = <String>[];
      final pattern = RegExp(r'(\S+|\s+)');
      final matches = pattern.allMatches(paragraph);
      
      for (final match in matches) {
        parts.add(match.group(0)!);
      }

      final wordSpans = <TextSpan>[];

      for (final part in parts) {
        // Check if this part is whitespace (including tabs, multiple spaces, etc.)
        if (RegExp(r'^\s+$').hasMatch(part)) {
          // Preserve all whitespace exactly as is
          wordSpans.add(
            TextSpan(
              text: part,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
          continue;
        }

        if (part.isEmpty) continue;

        // Extract punctuation and special characters from actual words
        final match = RegExp(r'^(\W*)(\w+)(\W*)$').firstMatch(part);
        if (match == null) {
          // If no word characters found, treat as punctuation/special chars
          wordSpans.add(
            TextSpan(
              text: part,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
          continue;
        }

        final prefix = match.group(1) ?? '';
        final coreWord = match.group(2) ?? '';
        final suffix = match.group(3) ?? '';

        if (coreWord.isEmpty) {
          wordSpans.add(
            TextSpan(
              text: part,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
          continue;
        }

        // Calculate bold length based on word length with improved algorithm
        int boldLength;
        if (coreWord.length <= 1) {
          boldLength = 1;
        } else if (coreWord.length <= 3) {
          boldLength = 1;
        } else if (coreWord.length <= 6) {
          boldLength = (coreWord.length * 0.5).ceil();
        } else {
          boldLength = (coreWord.length * 0.4).ceil();
        }

        final boldPart = coreWord.substring(0, boldLength);
        final regularPart = coreWord.substring(boldLength);

        // Add prefix (punctuation)
        if (prefix.isNotEmpty) {
          wordSpans.add(
            TextSpan(
              text: prefix,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
        }

        // Add bold part
        wordSpans.add(
          TextSpan(
            text: boldPart,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: _fontSize,
              height: _lineHeight,
            ),
          ),
        );

        // Add regular part
        if (regularPart.isNotEmpty) {
          wordSpans.add(
            TextSpan(
              text: regularPart,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
        }

        // Add suffix (punctuation)
        if (suffix.isNotEmpty) {
          wordSpans.add(
            TextSpan(
              text: suffix,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: _fontSize,
                height: _lineHeight,
              ),
            ),
          );
        }
      }

      paragraphSpans.add(TextSpan(children: wordSpans));

      // Add paragraph break except for the last paragraph
      if (p < paragraphs.length - 1) {
        paragraphSpans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      text: TextSpan(
        children: paragraphSpans,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildScrollingContent() {
    if (_fullText.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book title and author
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
              // Progress indicator
              Text(
                'Progress: ${(_progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Continuous bionic reading text
              _buildBionicText(_fullText),
              
              const SizedBox(height: 100), // Extra padding at bottom
            ],
          ),
        ),
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
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked
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
                if (_readingMode == ReadingMode.paging) ...[
                  IconButton(
                    onPressed: _previousPage,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Page',
                  ),
                  IconButton(
                    onPressed: _nextPage,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Page',
                  ),
                ],
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

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Bookmarked' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
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

  void _previousPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
      _saveProgress();
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    final newProgress = _progress;
    await BookService.instance.updateBookProgress(widget.book.id, newProgress);
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table of Contents',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: (_pages.length / 5)
                    .ceil(), // Show every 5th page as a chapter
                itemBuilder: (context, index) {
                  final pageIndex = index * 5;
                  final progress = pageIndex / _pages.length;
                  return _buildChapterItem(
                    'Page ${pageIndex + 1}',
                    pageIndex,
                    progress,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItem(String title, int pageIndex, double position) {
    return ListTile(
      title: Text(title),
      trailing: Text('${(position * 100).toInt()}%'),
      selected: pageIndex == _currentPageIndex,
      onTap: () {
        setState(() {
          _currentPageIndex = pageIndex.clamp(0, _pages.length - 1);
        });
        _saveProgress();
        Navigator.of(context).pop();
      },
    );
  }

  void _showReaderSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reader Settings'),
        content: Column(
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
              title: const Text('Reading Mode'),
              subtitle: Text(_readingMode == ReadingMode.paging ? 'Page by Page' : 'Continuous Scrolling'),
              trailing: Switch(
                value: _readingMode == ReadingMode.scrolling,
                onChanged: (value) {
                  setState(() {
                    _readingMode = value ? ReadingMode.scrolling : ReadingMode.paging;
                  });
                  Navigator.of(context).pop(); // Close dialog to show the change
                },
              ),
            ),
          ],
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
