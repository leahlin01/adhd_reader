import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart' hide SearchBar;
import 'reader_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data - in real app this would come from a database
  final List<Map<String, dynamic>> _books = [
    {
      'title': 'The Power of Habit',
      'author': 'Charles Duhigg',
      'progress': 0.75,
      'importDate': '2024-01-15',
      'coverImage': null,
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
      'progress': 0.45,
      'importDate': '2024-01-10',
      'coverImage': null,
    },
    {
      'title': 'Deep Work',
      'author': 'Cal Newport',
      'progress': 0.30,
      'importDate': '2024-01-05',
      'coverImage': null,
    },
    {
      'title': 'Getting Things Done',
      'author': 'David Allen',
      'progress': 0.90,
      'importDate': '2023-12-20',
      'coverImage': null,
    },
    {
      'title': 'The 7 Habits of Highly Effective People',
      'author': 'Stephen Covey',
      'progress': 0.60,
      'importDate': '2023-12-15',
      'coverImage': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredBooks {
    if (_searchQuery.isEmpty) {
      return _books;
    }
    return _books.where((book) {
      final title = book['title'].toString().toLowerCase();
      final author = book['author'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            onPressed: _showImportDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Import Book',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),

          // Books list
          Expanded(
            child: _filteredBooks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          title: book['title'],
                          author: book['author'],
                          coverImage: book['coverImage'],
                          progress: book['progress'],
                          onTap: () => _openBook(book),
                          onContinue: () => _continueReading(book),
                          onSettings: () => _showBookSettings(book),
                          onDelete: () => _deleteBook(book),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return EmptyState(
        title: 'No books found',
        message: 'Try adjusting your search terms',
        icon: Icons.search_off,
        action: TextButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
          child: const Text('Clear Search'),
        ),
      );
    }

    return EmptyState(
      title: 'Your library is empty',
      message: 'Import your first book to get started',
      icon: Icons.library_books,
      action: ActionButton(
        text: 'Import Book',
        icon: Icons.book,
        onPressed: _showImportDialog,
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Book'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how you want to import your book:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text('Upload File'),
              subtitle: Text('PDF, EPUB, TXT'),
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Import from URL'),
              subtitle: Text('Download from web'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement file upload
            },
            child: const Text('Upload File'),
          ),
        ],
      ),
    );
  }

  void _openBook(Map<String, dynamic> book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReaderPage(bookTitle: book['title'], bookAuthor: book['author']),
      ),
    );
  }

  void _continueReading(Map<String, dynamic> book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReaderPage(bookTitle: book['title'], bookAuthor: book['author']),
      ),
    );
  }

  void _showBookSettings(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${book['title']}'),
            Text('Author: ${book['author']}'),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Metadata'),
            ),
            const ListTile(
              leading: Icon(Icons.bookmark),
              title: Text('Manage Bookmarks'),
            ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Reading History'),
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

  void _deleteBook(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _books.remove(book);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${book['title']} deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
