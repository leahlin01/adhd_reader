import 'package:flutter/material.dart';
import '../services/book_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  double _pageMargin = 16.0;
  String _bionicIntensity = 'Medium';
  bool _isDarkMode = false;
  String _backgroundColor = 'White';
  String _fontFamily = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reading Settings
            _buildSectionHeader('Reading Settings'),
            _buildReadingSettingsCard(),
            const SizedBox(height: 24),

            // Theme Settings
            _buildSectionHeader('Theme Settings'),
            _buildThemeSettingsCard(),
            const SizedBox(height: 24),

            // Other Settings
            _buildSectionHeader('Other Settings'),
            _buildOtherSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildReadingSettingsCard() {
    return Card(
      child: Column(
        children: [
          _buildSettingItem(
            title: 'Font Size',
            subtitle: '${_fontSize.toInt()}px',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _fontSize = (_fontSize - 1).clamp(14.0, 24.0);
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _fontSize = (_fontSize + 1).clamp(14.0, 24.0);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Line Height',
            subtitle: _lineHeight.toString(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _lineHeight = (_lineHeight - 0.1).clamp(1.2, 2.0);
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _lineHeight = (_lineHeight + 0.1).clamp(1.2, 2.0);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Page Margin',
            subtitle: '${_pageMargin.toInt()}px',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _pageMargin = (_pageMargin - 4).clamp(8.0, 32.0);
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _pageMargin = (_pageMargin + 4).clamp(8.0, 32.0);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Bionic Intensity',
            subtitle: _bionicIntensity,
            trailing: DropdownButton<String>(
              value: _bionicIntensity,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _bionicIntensity = newValue;
                  });
                }
              },
              items: <String>['Light', 'Medium', 'Strong']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsCard() {
    return Card(
      child: Column(
        children: [
          _buildSettingItem(
            title: 'Theme Mode',
            subtitle: _isDarkMode ? 'Dark' : 'Light',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
                // In real app, this would change the app theme
              },
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Background Color',
            subtitle: _backgroundColor,
            trailing: DropdownButton<String>(
              value: _backgroundColor,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _backgroundColor = newValue;
                  });
                }
              },
              items: <String>['White', 'Cream', 'Light Gray', 'Sepia']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Font Family',
            subtitle: _fontFamily,
            trailing: DropdownButton<String>(
              value: _fontFamily,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _fontFamily = newValue;
                  });
                }
              },
              items: <String>['Inter', 'SF Pro Display', 'Roboto', 'Open Sans']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSettingsCard() {
    return Card(
      child: Column(
        children: [
          _buildSettingItem(
            title: 'About App',
            subtitle: 'Version information',
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAboutDialog,
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Help & Feedback',
            subtitle: 'Contact us',
            trailing: const Icon(Icons.chevron_right),
            onTap: _showHelpDialog,
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Privacy Policy',
            subtitle: 'View details',
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyDialog,
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Export Reading Data',
            subtitle: 'Backup your progress',
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Clean Up Invalid Books',
            subtitle: 'Remove books with missing files',
            trailing: const Icon(Icons.chevron_right),
            onTap: _showCleanupDialog,
          ),
          _buildDivider(),
          _buildSettingItem(
            title: 'Clear All Data',
            subtitle: 'Reset the app',
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ADHD Reader'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2024.01.15'),
            SizedBox(height: 8),
            Text(
              'ADHD Reader is designed to help people with ADHD focus better while reading through innovative techniques like Bionic Reading.',
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Feedback'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Here are some ways to get support:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Support'),
              subtitle: Text('support@adhdreader.com'),
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('FAQ'),
              subtitle: Text('Common questions and answers'),
            ),
            ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Report Bug'),
              subtitle: Text('Help us improve the app'),
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your privacy is important to us. This app:'),
              SizedBox(height: 8),
              Text('• Does not collect personal information'),
              Text('• Stores reading data locally on your device'),
              Text('• Does not share data with third parties'),
              Text('• Uses analytics only to improve app performance'),
              SizedBox(height: 16),
              Text('For the complete privacy policy, visit our website.'),
            ],
          ),
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

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting reading data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCleanupDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Up Invalid Books'),
        content: const Text(
          'This action will remove all books from your library that have missing files. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cleaning up invalid books...'),
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                // Perform cleanup
                await BookService.instance.cleanupInvalidBooks();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid books cleaned up successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cleaning up books: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all reading data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}
