import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/epub_book.dart';
import '../services/epub_parser.dart';
import '../services/bookmark_service.dart';
import '../theme/reading_theme.dart';
import '../widgets/epub_reader.dart';

class EpubReaderPage extends StatefulWidget {
  const EpubReaderPage({super.key});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubBook? _currentBook;
  ReadingSettings _settings = const ReadingSettings();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 这里可以从SharedPreferences加载保存的设置
    // 示例中使用默认设置
  }

  Future<void> _pickEpubFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final book = await EpubParser.parseEpubFile(filePath);

        setState(() {
          _currentBook = book;
        });

        // 显示书籍信息
        _showBookInfo(book);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载ePub文件失败: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookInfo(EpubBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('书籍信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标题: ${book.title}'),
            const SizedBox(height: 8),
            Text('作者: ${book.author}'),
            const SizedBox(height: 8),
            Text('章节数: ${book.chapters.length}'),
            const SizedBox(height: 8),
            Text('标识符: ${book.identifier}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onSettingsChanged(ReadingSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });

    // 保存设置到本地存储
    _saveSettings(newSettings);
  }

  Future<void> _saveSettings(ReadingSettings settings) async {
    // 这里可以保存设置到SharedPreferences
    print('保存设置: ${settings.toJson()}');
  }

  void _onPositionChanged(ReadingPosition position) {
    // 自动保存阅读进度
    if (_currentBook != null) {
      BookmarkService.saveReadingPosition(_currentBook!.identifier, position);
    }
  }

  void _onBookmarkAdded(Bookmark bookmark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('书签已添加到第${bookmark.chapterIndex + 1}章'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            _showBookmarks();
          },
        ),
      ),
    );
  }

  Future<void> _showBookmarks() async {
    if (_currentBook == null) return;

    final bookmarks = await BookmarkService.getBookmarks(
      _currentBook!.identifier,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('书签列表'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: bookmarks.isEmpty
              ? const Center(child: Text('暂无书签'))
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    final chapter =
                        _currentBook!.chapters[bookmark.chapterIndex];

                    return ListTile(
                      title: Text(chapter.title),
                      subtitle: Text(
                        '创建时间: ${_formatDateTime(bookmark.createdAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await BookmarkService.removeBookmark(
                            _currentBook!.identifier,
                            bookmark.id,
                          );
                          if (mounted) {
                            Navigator.of(context).pop();
                            _showBookmarks(); // 刷新列表
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ePub阅读器')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载ePub文件...'),
            ],
          ),
        ),
      );
    }

    if (_currentBook != null) {
      return EpubReader(
        book: _currentBook!,
        initialSettings: _settings,
        onSettingsChanged: _onSettingsChanged,
        onPositionChanged: _onPositionChanged,
        onBookmarkAdded: _onBookmarkAdded,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ePub阅读器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 120, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Flutter ePub阅读器',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '功能完整的ePub阅读器组件\n支持主题切换、书签、进度保存等功能',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _pickEpubFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择ePub文件', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFeatures,
                      icon: const Icon(Icons.star),
                      label: const Text('功能特性'),
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

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'ePub阅读器',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.menu_book, size: 48),
      children: [
        const Text('一个功能完整的Flutter ePub阅读器组件'),
        const SizedBox(height: 16),
        const Text('特性:'),
        const Text('• 支持ePub 2.0/3.0格式'),
        const Text('• 多种阅读主题'),
        const Text('• 字体大小调节'),
        const Text('• 书签和进度保存'),
        const Text('• 流畅的阅读体验'),
      ],
    );
  }

  void _showFeatures() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('功能特性'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeatureItem(
                icon: Icons.book,
                title: 'ePub支持',
                description: '完整支持ePub 2.0和3.0格式文件',
              ),
              _FeatureItem(
                icon: Icons.palette,
                title: '主题切换',
                description: '明亮、深色、护眼、夜间四种主题',
              ),
              _FeatureItem(
                icon: Icons.text_fields,
                title: '字体调节',
                description: '字体大小、行间距、页边距自由调节',
              ),
              _FeatureItem(
                icon: Icons.bookmark,
                title: '书签功能',
                description: '添加、删除、快速跳转书签',
              ),
              _FeatureItem(
                icon: Icons.save,
                title: '进度保存',
                description: '自动保存和恢复阅读位置',
              ),
              _FeatureItem(
                icon: Icons.speed,
                title: '性能优化',
                description: '大文件流畅加载，内存使用优化',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
