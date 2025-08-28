import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart' hide SearchBar;
import '../services/book_service.dart';
import 'reader_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  List<Book> get _filteredBooks {
    return BookService.instance.searchBooks(_books, _searchQuery);
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use validated books to ensure all file paths are correct
      final books = await BookService.instance.getValidatedBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load books: ${e.toString()}';
        _isLoading = false;
      });
    }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookCard(
                          title: book.title,
                          author: book.author,
                          coverImage: book.coverImagePath,
                          progress: book.progress,
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
            Text('Choose a book file to import:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text('Upload File'),
              subtitle: Text('EPUB, TXT'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _importBook();
            },
            child: const Text('Upload File'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBook() async {
    try {
      final book = await BookService.instance.importBook();
      if (book != null) {
        await _loadBooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported "${book.title}"'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to import book';

        // Provide more specific error messages
        if (e.toString().contains('iCloud')) {
          errorMessage =
              'iCloud files may not work in simulator. Please use local files or test on a real device.';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. Please check file access permissions.';
        } else if (e.toString().contains('not found')) {
          errorMessage =
              'File not found. The file may have been moved or deleted.';
        } else if (e.toString().contains('copy')) {
          errorMessage =
              'Failed to copy file. Please try again or use a different file.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _openBook(Book book) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ReaderPage(book: book)));
  }

  void _continueReading(Book book) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ReaderPage(book: book)));
  }

  void _showBookSettings(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${book.title}'),
            Text('Author: ${book.author}'),
            Text('File Type: ${book.fileType}'),
            Text(
              'File Size: ${(book.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            Text('Import Date: ${book.importDate.toString().split(' ')[0]}'),
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

  void _deleteBook(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final deletedTitle = book.title;
              Navigator.of(context).pop();
              await BookService.instance.deleteBook(book.id);
              await _loadBooks();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$deletedTitle" deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
