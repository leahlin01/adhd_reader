import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/book_service.dart';
import 'settings_page.dart';
import 'library_page.dart';
import 'reader_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> _recentBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentBooks();

    // 添加数据变化监听器
    BookService.instance.addDataChangeListener(_onDataChanged);
  }

  @override
  void dispose() {
    // 移除数据变化监听器
    BookService.instance.removeDataChangeListener(_onDataChanged);
    super.dispose();
  }

  /// 数据变化时的回调
  void _onDataChanged() {
    if (mounted) {
      _loadRecentBooks();
    }
  }

  Future<void> _loadRecentBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use validated books to ensure all file paths are correct
      final books = await BookService.instance.getValidatedBooks();
      books.sort((a, b) => b.importDate.compareTo(a.importDate));

      setState(() {
        _recentBooks = books.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recent books: $e');
      setState(() {
        _recentBooks = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADHD Reader'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(context),
            const SizedBox(height: 32),

            // Recent reading section
            _buildRecentReadingSection(context),
            const SizedBox(height: 32),

            // Quick actions section
            _buildQuickActionsSection(context),
            const SizedBox(height: 32),

            // Reading statistics section
            _buildReadingStatsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back!', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Start your focused reading journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReadingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reading',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentBooks.isEmpty
              ? const Center(
                  child: Text(
                    'No books yet. Add books from the Library tab.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentBooks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return _buildRecentBookCard(context, _recentBooks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecentBookCard(BuildContext context, Book book) {
    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ReaderPage(bookPath: book.filePath, bookTitle: book.title),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Book cover
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.book,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${book.author}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: book.progress,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(book.progress * 100).toInt()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ActionButton(
          text: 'Import New Book',
          icon: Icons.book,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LibraryPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        ActionButton(
          text: _recentBooks.isEmpty ? 'Import Book' : 'Continue Reading',
          icon: _recentBooks.isEmpty ? Icons.add : Icons.play_arrow,
          onPressed: () {
            if (_recentBooks.isEmpty) {
              // Navigate to library page to import books
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LibraryPage()),
              );
            } else {
              // Continue reading the most recent book
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReaderPage(
                    bookPath: _recentBooks.first.filePath,
                    bookTitle: _recentBooks.first.title,
                  ),
                ),
              );
            }
          },
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildReadingStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Statistics',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Today', '45 min', Icons.today),
                _buildStatItem(
                  context,
                  'This Week',
                  '3h 20m',
                  Icons.calendar_today,
                ),
                _buildStatItem(
                  context,
                  'Total Books',
                  '12',
                  Icons.library_books,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
