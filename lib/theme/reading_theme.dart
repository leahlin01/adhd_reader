import 'package:flutter/material.dart';

enum ReadingTheme { light, dark, sepia, night }

class ReadingThemeData {
  final Color backgroundColor;
  final Color textColor;
  final Color primaryColor;
  final Color secondaryColor;
  final String name;

  const ReadingThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.name,
  });

  static const Map<ReadingTheme, ReadingThemeData> themes = {
    ReadingTheme.light: ReadingThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF000000),
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF757575),
      name: '明亮',
    ),
    ReadingTheme.dark: ReadingThemeData(
      backgroundColor: Color(0xFF121212),
      textColor: Color(0xFFE0E0E0),
      primaryColor: Color(0xFF64B5F6),
      secondaryColor: Color(0xFF9E9E9E),
      name: '深色',
    ),
    ReadingTheme.sepia: ReadingThemeData(
      backgroundColor: Color(0xFFF5F5DC),
      textColor: Color(0xFF5D4037),
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFF795548),
      name: '护眼',
    ),
    ReadingTheme.night: ReadingThemeData(
      backgroundColor: Color(0xFF000000),
      textColor: Color(0xFF4CAF50),
      primaryColor: Color(0xFF66BB6A),
      secondaryColor: Color(0xFF81C784),
      name: '夜间',
    ),
  };

  static ReadingThemeData getTheme(ReadingTheme theme) {
    return themes[theme] ?? themes[ReadingTheme.light]!;
  }
}

class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final ReadingTheme theme;
  final String fontFamily;
  final double pageMargin;
  final bool bionicReadingEnabled;
  final double bionicBoldRatio;

  const ReadingSettings({
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.theme = ReadingTheme.light,
    this.fontFamily = 'System',
    this.pageMargin = 16.0,
    this.bionicReadingEnabled = false,
    this.bionicBoldRatio = 0.5,
  });

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    ReadingTheme? theme,
    String? fontFamily,
    double? pageMargin,
    bool? bionicReadingEnabled,
    double? bionicBoldRatio,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      pageMargin: pageMargin ?? this.pageMargin,
      bionicReadingEnabled: bionicReadingEnabled ?? this.bionicReadingEnabled,
      bionicBoldRatio: bionicBoldRatio ?? this.bionicBoldRatio,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'theme': theme.index,
    'fontFamily': fontFamily,
    'pageMargin': pageMargin,
    'bionicReadingEnabled': bionicReadingEnabled,
    'bionicBoldRatio': bionicBoldRatio,
  };

  factory ReadingSettings.fromJson(Map<String, dynamic> json) =>
      ReadingSettings(
        fontSize: json['fontSize']?.toDouble() ?? 16.0,
        lineHeight: json['lineHeight']?.toDouble() ?? 1.5,
        theme: ReadingTheme.values[json['theme'] ?? 0],
        fontFamily: json['fontFamily'] ?? 'System',
        pageMargin: json['pageMargin']?.toDouble() ?? 16.0,
        bionicReadingEnabled: json['bionicReadingEnabled'] ?? false,
        bionicBoldRatio: json['bionicBoldRatio']?.toDouble() ?? 0.5,
      );
}
