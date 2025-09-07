import 'package:flutter/material.dart';
import '../services/book_service.dart';
import 'reader_page.dart';
import 'dart:io';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('=== Library页面initState开始 ===');
    _loadBooks();

    // 添加数据变化监听器
    debugPrint('Library页面准备添加数据变化监听器');
    BookService.instance.addDataChangeListener(_onDataChanged);
    debugPrint('Library页面数据变化监听器添加完成');
  }

  @override
  void dispose() {
    debugPrint('=== Library页面dispose开始 ===');
    // 移除数据变化监听器
    debugPrint('Library页面准备移除数据变化监听器');
    BookService.instance.removeDataChangeListener(_onDataChanged);
    debugPrint('Library页面数据变化监听器移除完成');
    super.dispose();
  }

  /// 数据变化时的回调
  void _onDataChanged() {
    debugPrint('=== Library页面收到数据变化通知 ===');
    if (mounted) {
      debugPrint('Library页面仍然mounted，开始重新加载书籍');
      _loadBooks();
    } else {
      debugPrint('Library页面已unmounted，跳过重新加载');
    }
  }

  Future<void> _loadBooks() async {
    debugPrint('=== Library页面开始加载书籍 ===');
    setState(() {
      _isLoading = true;
    });

    try {
      // Use validated books to ensure all file paths are correct
      final books = await BookService.instance.getValidatedBooks();
      debugPrint('加载到的书籍数量: ${books.length}');
      setState(() {
        _books = books;
        _isLoading = false;
      });
      debugPrint('Library页面书籍列表已更新');
    } catch (e) {
      debugPrint('Library页面加载书籍失败: $e');
      setState(() {
        _errorMessage = 'Failed to load books: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ],
              ),
            ),

            // Books list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _books.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildBookItem(book),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItem(Book book) {
    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Book cover
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: book.coverImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(book.coverImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('封面图片加载失败: $error');
                          debugPrint('封面图片路径: ${book.coverImagePath}');
                          debugPrint('错误堆栈: $stackTrace');

                          // 检查文件是否存在
                          final file = File(book.coverImagePath!);
                          file.exists().then((exists) {
                            debugPrint('文件是否存在: $exists');
                            if (exists) {
                              file.length().then((length) {
                                debugPrint('文件大小: $length bytes');
                                // 尝试读取文件的前几个字节来检查文件头
                                file
                                    .readAsBytes()
                                    .then((bytes) {
                                      if (bytes.isNotEmpty) {
                                        debugPrint(
                                          '文件头字节: ${bytes.take(8).toList()}',
                                        );
                                      }
                                    })
                                    .catchError((e) {
                                      debugPrint('读取文件字节失败: $e');
                                    });
                              });
                            }
                          });

                          // 删除无效的封面文件
                          _deleteInvalidCoverFile(book.coverImagePath!);

                          return _buildCoverPlaceholder();
                        },
                      ),
                    )
                  : _buildCoverPlaceholder(),
            ),
            const SizedBox(width: 16),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Author: ${book.author}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.book, size: 32, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Import your first book to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showImportDialog,
              icon: const Icon(Icons.book),
              label: const Text('Import Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
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
      // 直接调用BookService导入书籍
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReaderPage(bookPath: book.filePath, bookTitle: book.title),
      ),
    );
  }

  /// 删除无效的封面文件
  void _deleteInvalidCoverFile(String coverPath) {
    try {
      final file = File(coverPath);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('已删除无效的封面文件: $coverPath');
      }
    } catch (e) {
      debugPrint('删除无效封面文件失败: $e');
    }
  }
}
