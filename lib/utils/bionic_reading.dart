import 'dart:math';

/// Bionic Reading 文本处理工具类
class BionicReading {
  /// 将普通文本转换为 Bionic Reading 格式
  /// [text] 原始文本
  /// [boldRatio] 加粗比例 (0.0-1.0)，默认0.5表示前50%字符加粗
  static String convertToBionicReading(String text, {double boldRatio = 0.5}) {
    if (text.isEmpty) return text;

    // 使用正则表达式匹配单词（包括中文字符）
    final wordPattern = RegExp(r'[\w\u4e00-\u9fff]+');

    return text.replaceAllMapped(wordPattern, (match) {
      final word = match.group(0)!;
      return _processSingleWord(word, boldRatio);
    });
  }

  /// 将HTML内容转换为 Bionic Reading 格式
  /// 保留HTML标签，只处理文本内容
  static String convertHtmlToBionicReading(
    String html, {
    double boldRatio = 0.5,
  }) {
    if (html.isEmpty) return html;

    // 匹配HTML标签外的文本内容
    final textPattern = RegExp(r'>([^<]+)<');

    String result = html;

    // 处理标签之间的文本
    result = result.replaceAllMapped(textPattern, (match) {
      final fullMatch = match.group(0)!;
      final textContent = match.group(1)!;
      final processedText = convertToBionicReading(
        textContent,
        boldRatio: boldRatio,
      );
      return fullMatch.replaceFirst(textContent, processedText);
    });

    // 处理开头和结尾的文本（不在标签内的）
    final startTextPattern = RegExp(r'^([^<]+)');
    result = result.replaceAllMapped(startTextPattern, (match) {
      final text = match.group(1)!;
      return convertToBionicReading(text, boldRatio: boldRatio);
    });

    final endTextPattern = RegExp(r'>([^<]+)$');
    result = result.replaceAllMapped(endTextPattern, (match) {
      final fullMatch = match.group(0)!;
      final text = match.group(1)!;
      final processedText = convertToBionicReading(text, boldRatio: boldRatio);
      return fullMatch.replaceFirst(text, processedText);
    });

    return result;
  }

  /// 处理单个单词
  static String _processSingleWord(String word, double boldRatio) {
    if (word.length <= 1) return word;

    // 计算需要加粗的字符数量
    int boldLength = max(1, (word.length * boldRatio).round());

    // 确保不超过单词长度
    boldLength = min(boldLength, word.length - 1);

    final boldPart = word.substring(0, boldLength);
    final normalPart = word.substring(boldLength);

    return '<b>$boldPart</b>$normalPart';
  }

  /// 智能处理不同语言的单词
  static String convertToSmartBionicReading(
    String text, {
    double boldRatio = 0.5,
  }) {
    if (text.isEmpty) return text;

    // 分别处理英文单词和中文字符
    final mixedPattern = RegExp(r'[\w]+|[\u4e00-\u9fff]');

    return text.replaceAllMapped(mixedPattern, (match) {
      final word = match.group(0)!;

      // 判断是否为中文字符
      if (RegExp(r'[\u4e00-\u9fff]').hasMatch(word)) {
        // 中文字符单独处理，每个字符都可以加粗
        if (word.length == 1) {
          return '<b>$word</b>';
        } else {
          return _processSingleWord(word, boldRatio);
        }
      } else {
        // 英文单词处理
        return _processSingleWord(word, boldRatio);
      }
    });
  }

  /// 清理HTML中的嵌套粗体标签
  static String cleanNestedBoldTags(String html) {
    // 移除嵌套的<b>标签
    html = html.replaceAll(
      RegExp(r'<b>([^<]*)<b>([^<]*)</b>([^<]*)</b>'),
      '<b>\$1\$2\$3</b>',
    );

    // 合并相邻的<b>标签
    html = html.replaceAll(RegExp(r'</b><b>'), '');

    return html;
  }
}
