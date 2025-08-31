/// 纯Dart日志工具类 - 不依赖Flutter
class PureLogger {
  static const String _tag = 'EPUB_Parser';

  /// 调试日志
  static void debug(String message, [String? tag]) {
    print('🐛 [${tag ?? _tag}] $message');
  }

  /// 信息日志
  static void info(String message, [String? tag]) {
    print('ℹ️ [${tag ?? _tag}] $message');
  }

  /// 警告日志
  static void warning(String message, [String? tag]) {
    print('⚠️ [${tag ?? _tag}] $message');
  }

  /// 错误日志
  static void error(String message, [Object? error, String? tag]) {
    print('❌ [${tag ?? _tag}] $message');
    if (error != null) {
      print('❌ [${tag ?? _tag}] Error: $error');
    }
  }

  /// 强制打印（总是显示）
  static void force(String message, [String? tag]) {
    print('🔥 [${tag ?? _tag}] $message');
  }
}
