import 'package:flutter/material.dart';

class ReaderPage extends StatefulWidget {
  final String bookTitle;
  final String bookAuthor;

  const ReaderPage({
    super.key,
    required this.bookTitle,
    required this.bookAuthor,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  double _progress = 0.25;
  bool _showToolbar = true;
  bool _isBookmarked = false;

  // Mock text content for demonstration
  final String _sampleText = '''
This is a sample text that demonstrates bionic reading. The first few letters of each word are bolded to help your brain recognize words faster.

This technique can improve reading speed by 20-30% and reduce visual fatigue. It works by making the first few letters of each word stand out, allowing your brain to process the text more efficiently.

Bionic reading is particularly helpful for people with ADHD, as it reduces the cognitive load required to process text and helps maintain focus on the content.

The bolded letters act as anchors for your eyes, making it easier to scan through the text while maintaining comprehension. This method has been shown to improve reading speed without sacrificing understanding.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: GestureDetector(
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
            _buildReadingContent(),

            // Top toolbar
            if (_showToolbar) _buildTopToolbar(),

            // Bottom control bar
            if (_showToolbar) _buildBottomControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book title and author
              Text(
                widget.bookTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'by ${widget.bookAuthor}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Bionic reading text
              _buildBionicText(_sampleText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBionicText(String text) {
    final words = text.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) {
        spans.add(const TextSpan(text: ' '));
        continue;
      }

      // Bold the first few letters (approximately 40% of the word)
      final boldLength = (word.length * 0.4).ceil();
      final boldPart = word.substring(0, boldLength);
      final regularPart = word.substring(boldLength);

      spans.add(
        TextSpan(
          text: boldPart,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: _fontSize,
            height: _lineHeight,
          ),
        ),
      );

      if (regularPart.isNotEmpty) {
        spans.add(
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

      // Add space between words
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
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
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                        widget.bookTitle,
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
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
    setState(() {
      _progress = (_progress - 0.05).clamp(0.0, 1.0);
    });
  }

  void _nextPage() {
    setState(() {
      _progress = (_progress + 0.05).clamp(0.0, 1.0);
    });
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
              child: ListView(
                children: [
                  _buildChapterItem('Chapter 1: Introduction', 0.0),
                  _buildChapterItem('Chapter 2: Getting Started', 0.25),
                  _buildChapterItem('Chapter 3: Core Concepts', 0.50),
                  _buildChapterItem('Chapter 4: Advanced Techniques', 0.75),
                  _buildChapterItem('Chapter 5: Conclusion', 1.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItem(String title, double position) {
    return ListTile(
      title: Text(title),
      trailing: Text('${(position * 100).toInt()}%'),
      onTap: () {
        setState(() {
          _progress = position;
        });
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
