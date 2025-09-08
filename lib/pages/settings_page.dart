import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFontFamilyBold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Appearance 部分
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 16),
              _buildAppearanceSection(),
              const SizedBox(height: 16),

              // Support 部分
              _buildSectionHeader('Support'),
              const SizedBox(height: 16),
              _buildSupportSection(),
              const SizedBox(height: 16),

              // About 部分
              _buildSectionHeader('About'),
              const SizedBox(height: 16),
              _buildAboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.primaryFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      children: [
        _buildSimpleSettingItem(
          title: 'Theme',
          trailing: Switch(
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
            },
            activeColor: Colors.black,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          customPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 4.0,
          ), // 自定义 padding
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSimpleSettingItem(
          title: 'Contact Author',
          trailing: Text(
            'leahlin2022@qq.com',
            style: TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildSimpleSettingItem(
          title: 'Version',
          trailing: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showAboutDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFontFamily,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.black, size: 24),
              ],
            ),
          ),
        ),
        _buildSimpleSettingItem(
          title: 'Clear All Data',
          trailing: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showClearDataDialog,
            child: const Icon(
              Icons.chevron_right,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
        _buildSimpleSettingItem(
          title: 'Privacy Policy',
          trailing: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showPrivacyDialog,
            child: const Icon(
              Icons.chevron_right,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSettingItem({
    required String title,
    Widget? trailing,
    EdgeInsets? customPadding,
  }) {
    return Padding(
      padding:
          customPadding ??
          const EdgeInsets.symmetric(horizontal: 0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.primaryFontFamily,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  // 保留原有的对话框方法，但简化内容
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About ADHD Reader',
          style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
            const SizedBox(height: 8),
            Text(
              'Build: 2024.01.15',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
            const SizedBox(height: 8),
            Text(
              'ADHD Reader is designed to help people with ADHD focus better while reading through innovative techniques like Bionic Reading.',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Help & Feedback',
          style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help? Here are some ways to get support:',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(
                'Email Support',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              subtitle: Text(
                'leahlin2022@qq.com',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Policy',
          style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your privacy is important to us. This app:',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              const SizedBox(height: 8),
              Text(
                '• Does not collect personal information',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              Text(
                '• Stores reading data locally on your device',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              Text(
                '• Does not share data with third parties',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              Text(
                '• Uses analytics only to improve app performance',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
              const SizedBox(height: 16),
              Text(
                'For the complete privacy policy, visit our website.',
                style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Data',
          style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
        ),
        content: Text(
          'Are you sure you want to clear all reading data? This action cannot be undone.',
          style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Clearing all data...',
                      style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              try {
                debugPrint('=== 设置页面开始清空数据 ===');
                await BookService.instance.clearAllData();
                debugPrint('=== 设置页面清空数据完成 ===');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'All data cleared successfully',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('=== 设置页面清空数据失败: $e ===');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error clearing data: $e',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFontFamily,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Clear Data',
              style: TextStyle(fontFamily: AppTheme.primaryFontFamily),
            ),
          ),
        ],
      ),
    );
  }
}
