import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverImage;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onContinue;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    this.coverImage,
    required this.progress,
    this.onTap,
    this.onContinue,
    this.onSettings,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book cover placeholder
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCoverPlaceholder(context),
                        ),
                      )
                    : _buildCoverPlaceholder(context),
              ),
              const SizedBox(width: 16),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Action buttons
              if (onContinue != null || onSettings != null || onDelete != null)
                Column(
                  children: [
                    if (onContinue != null)
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          child: const Text('Continue'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (onSettings != null || onDelete != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onSettings != null)
                            IconButton(
                              onPressed: onSettings,
                              icon: const Icon(Icons.settings),
                              tooltip: 'Settings',
                            ),
                          if (onDelete != null)
                            IconButton(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.book,
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;

  const ProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: valueColor ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
      );
    } else {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
      );
    }
  }
}

class SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const SearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(onPressed: onClear, icon: const Icon(Icons.clear))
            : null,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
