# Flutter ePub 阅读器组件

一个功能完整、性能优化的 Flutter ePub 阅读器组件，支持 ePub 格式文件的解析与渲染，提供流畅的阅读体验。

## 特性

- ✅ **完整的 ePub 支持**: 支持 ePub 2.0 和 3.0 格式
- ✅ **流畅的阅读体验**: 优化的滚动和翻页效果
- ✅ **自定义主题**: 支持明亮、深色、护眼、夜间四种主题
- ✅ **字体调节**: 支持字体大小、行间距、页边距调整
- ✅ **书签功能**: 添加、删除、跳转书签
- ✅ **阅读进度**: 自动保存和恢复阅读位置
- ✅ **章节导航**: 快速跳转到任意章节
- ✅ **跨平台**: 完美支持 iOS 和 Android
- ✅ **性能优化**: 大文件加载流畅，内存使用优化

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  archive: ^3.4.10
  xml: ^6.4.2
  html: ^0.15.4
  path: ^1.8.3
  shared_preferences: ^2.2.2
  flutter_html: ^3.0.0-beta.2
  path_provider: ^2.1.1
```

## 快速开始

### 1. 基本使用

```dart
import 'package:flutter/material.dart';
import 'package:your_app/widgets/epub_reader.dart';
import 'package:your_app/services/epub_parser.dart';

class MyEpubReader extends StatefulWidget {
  @override
  _MyEpubReaderState createState() => _MyEpubReaderState();
}

class _MyEpubReaderState extends State<MyEpubReader> {
  EpubBook? book;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    // 从文件路径加载ePub
    final loadedBook = await EpubParser.parseEpubFile('/path/to/book.epub');
    setState(() {
      book = loadedBook;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return EpubReader(
      book: book!,
      initialSettings: ReadingSettings(
        fontSize: 16.0,
        theme: ReadingTheme.light,
      ),
      onSettingsChanged: (settings) {
        // 保存用户设置
        print('设置已更改: $settings');
      },
      onPositionChanged: (position) {
        // 保存阅读进度
        print('阅读位置: ${position.chapterIndex}');
      },
      onBookmarkAdded: (bookmark) {
        // 处理书签添加
        print('书签已添加: ${bookmark.id}');
      },
    );
  }
}
```

### 2. 从字节数组加载

```dart
// 从网络或其他来源获取ePub字节数据
Uint8List epubBytes = await getEpubBytesFromNetwork();
EpubBook book = await EpubParser.parseEpubBytes(epubBytes);
```

### 3. 自定义阅读设置

```dart
ReadingSettings customSettings = ReadingSettings(
  fontSize: 18.0,           // 字体大小
  lineHeight: 1.6,          // 行间距
  theme: ReadingTheme.sepia, // 护眼主题
  fontFamily: 'Georgia',     // 字体族
  pageMargin: 20.0,         // 页边距
);

EpubReader(
  book: book,
  initialSettings: customSettings,
  // ...其他参数
)
```

## API 文档

### EpubReader 组件

主要的阅读器组件，提供完整的 ePub 阅读功能。

#### 构造函数参数

| 参数                | 类型                         | 必需 | 描述                   |
| ------------------- | ---------------------------- | ---- | ---------------------- |
| `book`              | `EpubBook`                   | ✅   | 要显示的 ePub 书籍对象 |
| `initialSettings`   | `ReadingSettings`            | ❌   | 初始阅读设置           |
| `onSettingsChanged` | `Function(ReadingSettings)?` | ❌   | 设置更改回调           |
| `onPositionChanged` | `Function(ReadingPosition)?` | ❌   | 阅读位置更改回调       |
| `onBookmarkAdded`   | `Function(Bookmark)?`        | ❌   | 书签添加回调           |

#### 示例

```dart
EpubReader(
  book: myBook,
  initialSettings: ReadingSettings(fontSize: 16.0),
  onSettingsChanged: (settings) {
    // 保存设置到本地存储
    saveSettingsToLocal(settings);
  },
  onPositionChanged: (position) {
    // 自动保存阅读进度
    BookmarkService.saveReadingPosition(myBook.identifier, position);
  },
  onBookmarkAdded: (bookmark) {
    // 显示书签添加成功提示
    showSnackBar('书签已添加');
  },
)
```

### EpubParser 服务

用于解析 ePub 文件的工具类。

#### 方法

##### `parseEpubFile(String filePath)`

从文件路径解析 ePub 文件。

```dart
EpubBook book = await EpubParser.parseEpubFile('/path/to/book.epub');
```

##### `parseEpubBytes(Uint8List bytes)`

从字节数组解析 ePub 文件。

```dart
Uint8List bytes = await file.readAsBytes();
EpubBook book = await EpubParser.parseEpubBytes(bytes);
```

### BookmarkService 服务

管理书签和阅读进度的服务类。

#### 方法

##### 书签管理

```dart
// 获取书签列表
List<Bookmark> bookmarks = await BookmarkService.getBookmarks(bookId);

// 添加书签
await BookmarkService.addBookmark(bookmark);

// 删除书签
await BookmarkService.removeBookmark(bookId, bookmarkId);
```

##### 阅读进度管理

```dart
// 获取阅读位置
ReadingPosition? position = await BookmarkService.getReadingPosition(bookId);

// 保存阅读位置
await BookmarkService.saveReadingPosition(bookId, position);
```

### 数据模型

#### EpubBook

```dart
class EpubBook {
  final String title;           // 书籍标题
  final String author;          // 作者
  final String identifier;      // 唯一标识符
  final List<EpubChapter> chapters; // 章节列表
  final Map<String, String> resources; // 资源文件
  final String? coverImage;    // 封面图片
}
```

#### EpubChapter

```dart
class EpubChapter {
  final String id;             // 章节ID
  final String title;          // 章节标题
  final String content;        // 章节内容(HTML)
  final String href;           // 文件路径
  final int order;             // 章节顺序
}
```

#### ReadingSettings

```dart
class ReadingSettings {
  final double fontSize;       // 字体大小 (12-24)
  final double lineHeight;     // 行间距 (1.0-2.5)
  final ReadingTheme theme;    // 阅读主题
  final String fontFamily;     // 字体族
  final double pageMargin;     // 页边距 (8-32)
}
```

#### ReadingTheme

```dart
enum ReadingTheme {
  light,    // 明亮主题
  dark,     // 深色主题
  sepia,    // 护眼主题
  night,    // 夜间主题
}
```

#### Bookmark

```dart
class Bookmark {
  final String id;             // 书签ID
  final String bookId;         // 书籍ID
  final int chapterIndex;      // 章节索引
  final double scrollOffset;   // 滚动偏移
  final String? note;          // 书签备注
  final DateTime createdAt;    // 创建时间
}
```

#### ReadingPosition

```dart
class ReadingPosition {
  final int chapterIndex;      // 当前章节索引
  final double scrollOffset;   // 滚动偏移量
  final DateTime timestamp;    // 时间戳
}
```

## 高级用法

### 1. 自定义主题

```dart
// 创建自定义主题数据
ReadingThemeData customTheme = ReadingThemeData(
  backgroundColor: Color(0xFFF0F0F0),
  textColor: Color(0xFF333333),
  primaryColor: Color(0xFF007AFF),
  secondaryColor: Color(0xFF666666),
  name: '自定义',
);

// 在阅读器中使用
ReadingSettings settings = ReadingSettings(
  theme: ReadingTheme.light, // 使用预设主题
  // 或者扩展ReadingTheme枚举来支持自定义主题
);
```

### 2. 批量书签操作

```dart
class BookmarkManager {
  static Future<void> exportBookmarks(String bookId) async {
    List<Bookmark> bookmarks = await BookmarkService.getBookmarks(bookId);
    // 导出书签到文件
  }

  static Future<void> importBookmarks(String bookId, List<Bookmark> bookmarks) async {
    for (Bookmark bookmark in bookmarks) {
      await BookmarkService.addBookmark(bookmark);
    }
  }
}
```

### 3. 阅读统计

```dart
class ReadingStats {
  static Future<Duration> getTotalReadingTime(String bookId) async {
    // 计算总阅读时间
  }

  static Future<double> getReadingProgress(String bookId, EpubBook book) async {
    ReadingPosition? position = await BookmarkService.getReadingPosition(bookId);
    if (position == null) return 0.0;

    // 计算阅读进度百分比
    return (position.chapterIndex + 1) / book.chapters.length;
  }
}
```

## 性能优化

### 1. 大文件处理

组件已内置以下优化：

- **懒加载**: 章节内容按需加载
- **内存管理**: 自动释放不需要的资源
- **图片优化**: 图片资源 base64 编码存储
- **滚动优化**: 使用 SingleChildScrollView 优化滚动性能

### 2. 自定义优化

```dart
// 预加载下一章节
class ChapterPreloader {
  static Future<void> preloadNextChapter(EpubBook book, int currentIndex) async {
    if (currentIndex + 1 < book.chapters.length) {
      // 预加载逻辑
    }
  }
}
```

## 故障排除

### 常见问题

1. **ePub 文件解析失败**

   - 确保文件格式正确
   - 检查文件是否损坏
   - 验证文件权限

2. **字体显示异常**

   - 检查系统字体支持
   - 使用 fallback 字体

3. **性能问题**
   - 减少同时加载的章节数量
   - 优化图片资源大小

### 调试模式

```dart
// 启用调试日志
EpubReader(
  book: book,
  // 添加调试回调
  onPositionChanged: (position) {
    print('DEBUG: 位置变化 - 章节:${position.chapterIndex}, 偏移:${position.scrollOffset}');
  },
)
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个组件。

## 更新日志

### v1.0.0

- 初始版本发布
- 支持基本的 ePub 阅读功能
- 实现主题切换和字体调节
- 添加书签和进度保存功能
