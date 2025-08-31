import 'package:flutter/material.dart';
import '../models/epub_book.dart';
import '../services/bookmark_service.dart';
import '../theme/reading_theme.dart';

class ReadingControls extends StatefulWidget {
  final EpubBook book;
  final ReadingSettings settings;
  final int currentChapterIndex;
  final List<Bookmark> bookmarks;
  final Function(ReadingSettings) onSettingsChanged;
  final Function(int) onChapterChanged;
  final VoidCallback onAddBookmark;
  final VoidCallback onClose;

  const ReadingControls({
    Key? key,
    required this.book,
    required this.settings,
    required this.currentChapterIndex,
    required this.bookmarks,
    required this.onSettingsChanged,
    required this.onChapterChanged,
    required this.onAddBookmark,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ReadingControls> createState() => _ReadingControlsState();
}

class _ReadingControlsState extends State<ReadingControls>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
            height: 80,
            padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.book.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onAddBookmark,
                      icon: const Icon(Icons.bookmark_add),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Tab栏
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: '目录'),
                      Tab(text: '设置'),
                      Tab(text: '书签'),
                    ],
                  ),

                  // Tab内容
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChapterList(),
                        _buildSettings(),
                        _buildBookmarks(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    return ListView.builder(
      itemCount: widget.book.chapters.length,
      itemBuilder: (context, index) {
        final chapter = widget.book.chapters[index];
        final isCurrentChapter = index == widget.currentChapterIndex;

        return ListTile(
          title: Text(
            chapter.title,
            style: TextStyle(
              fontWeight: isCurrentChapter
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isCurrentChapter ? Colors.blue : Colors.black,
            ),
          ),
          leading: Text(
            '${index + 1}',
            style: TextStyle(
              color: isCurrentChapter ? Colors.blue : Colors.grey,
            ),
          ),
          onTap: () {
            widget.onChapterChanged(index);
            widget.onClose();
          },
        );
      },
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 字体大小
          const Text(
            '字体大小',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: widget.settings.fontSize > 12
                    ? () {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(
                            fontSize: widget.settings.fontSize - 1,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  value: widget.settings.fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: widget.settings.fontSize.round().toString(),
                  onChanged: (value) {
                    widget.onSettingsChanged(
                      widget.settings.copyWith(fontSize: value),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: widget.settings.fontSize < 24
                    ? () {
                        widget.onSettingsChanged(
                          widget.settings.copyWith(
                            fontSize: widget.settings.fontSize + 1,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 行间距
          const Text(
            '行间距',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Slider(
            value: widget.settings.lineHeight,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            label: widget.settings.lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              widget.onSettingsChanged(
                widget.settings.copyWith(lineHeight: value),
              );
            },
          ),

          const SizedBox(height: 20),

          // 主题选择
          const Text(
            '阅读主题',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReadingTheme.values.map((theme) {
              final themeData = ReadingThemeData.getTheme(theme);
              final isSelected = widget.settings.theme == theme;

              return GestureDetector(
                onTap: () {
                  widget.onSettingsChanged(
                    widget.settings.copyWith(theme: theme),
                  );
                },
                child: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeData.backgroundColor,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      themeData.name,
                      style: TextStyle(
                        color: themeData.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 页边距
          const Text(
            '页边距',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Slider(
            value: widget.settings.pageMargin,
            min: 8,
            max: 32,
            divisions: 12,
            label: widget.settings.pageMargin.round().toString(),
            onChanged: (value) {
              widget.onSettingsChanged(
                widget.settings.copyWith(pageMargin: value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarks() {
    if (widget.bookmarks.isEmpty) {
      return const Center(child: Text('暂无书签'));
    }

    return ListView.builder(
      itemCount: widget.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = widget.bookmarks[index];
        final chapter = widget.book.chapters[bookmark.chapterIndex];

        return ListTile(
          title: Text(chapter.title),
          subtitle: Text(
            '添加时间: ${_formatDateTime(bookmark.createdAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await BookmarkService.removeBookmark(
                widget.book.identifier,
                bookmark.id,
              );
              // 这里需要刷新书签列表，实际应用中可以通过状态管理来处理
            },
          ),
          onTap: () {
            widget.onChapterChanged(bookmark.chapterIndex);
            widget.onClose();
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
