import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../services/book_service.dart';
import 'settings_page.dart';
import 'library_page.dart';
import 'reader_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToLibrary;

  const HomePage({super.key, this.onNavigateToLibrary});

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
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              child: Text(
                'Bionic Reading',
                style: const TextStyle(
                  fontFamily: 'Spline Sans',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 主要内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 大标题
                    Text(
                      'Unlock Focus with\nBionic Reading',
                      style: const TextStyle(
                        fontFamily: 'Spline Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 描述文字
                    Text(
                      'Transform your reading experience with our innovative approach, designed to enhance focus and comprehension for individuals with ADHD.',
                      style: TextStyle(
                        fontFamily: 'Spline Sans',
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Get Started 按钮
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_recentBooks.isEmpty) {
                            // 使用回调函数切换到Library页面
                            widget.onNavigateToLibrary?.call();
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _recentBooks.isEmpty
                              ? 'Get Started'
                              : 'Continue Reading',
                          style: const TextStyle(
                            fontFamily: 'Spline Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
