# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ADHD Reader is a Flutter-based mobile application designed specifically for people with ADHD to improve their reading experience through innovative Bionic Reading techniques. The app currently supports iOS, Android, Web, and Desktop platforms.

## Key Technologies

- **Framework**: Flutter 3.9.0+
- **Language**: Dart
- **Architecture**: StatefulWidget-based state management with clean separation of concerns
- **Target Platforms**: iOS (primary focus), Android, Web, Desktop

## Development Commands

### Essential Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Build for production
flutter build ios
flutter build android
flutter build web

# Run tests
flutter test

# Analyze code (linting)
flutter analyze

# Format code
dart format .
```

### Platform-Specific Commands

```bash
# iOS development
flutter run -d ios
open ios/Runner.xcworkspace  # Open in Xcode for iOS-specific configuration

# Android development
flutter run -d android

# Web development
flutter run -d chrome

# Desktop (macOS)
flutter run -d macos
```

## Architecture Overview

### Project Structure

```
lib/
├── main.dart                 # App entry point with bottom navigation
├── theme/
│   └── app_theme.dart       # Centralized theme configuration (light/dark)
├── pages/
│   ├── home_page.dart       # Home dashboard with recent books
│   ├── library_page.dart    # Book management and library view
│   ├── reader_page.dart     # Bionic reading interface
│   └── settings_page.dart   # User preferences and app settings
└── widgets/
    └── common_widgets.dart  # Reusable UI components
```

### Core Application Flow

1. **Main App**: Bottom navigation between Home, Library, and Settings
2. **Home Page**: Welcome message, recent reading, quick actions, reading statistics
3. **Library Page**: Book search, import functionality, book management
4. **Reader Page**: Bionic Reading implementation with text formatting
5. **Settings Page**: Reading preferences, themes, accessibility options

## Key Features to Understand

### Bionic Reading Implementation

The core feature is Bionic Reading - making the first 40% of each word bold to help the brain recognize words faster and maintain focus. This is particularly beneficial for ADHD users.

### Design Principles

- **Simplified Interface**: Clean, distraction-free design optimized for ADHD users
- **High Contrast**: Text readability with customizable themes
- **Large Touch Targets**: Easy navigation and accessibility
- **Responsive Design**: Adapts to different screen sizes and orientations

### Color Scheme

- **Primary**: #2563EB (Blue) - Focus and trust
- **Secondary**: #10B981 (Green) - Success and progress  
- **Accent**: #F59E0B (Orange) - Important information
- **Typography**: Inter font family, 18px default reading text

## Development Guidelines

### State Management

The app uses Flutter's built-in StatefulWidget pattern. When making changes:

- Use `setState()` for local state updates
- Ensure proper disposal of controllers and listeners
- Follow the existing pattern of IndexedStack for page navigation

### Theme System

The app has a centralized theme system (`app_theme.dart`) supporting:

- Light and dark themes
- System theme detection
- Consistent color palette
- Typography scales optimized for reading

### File Format Support

Currently supported formats:
- **EPUB format** - Primary ebook format with rich formatting support
- **TXT format** - Plain text files for simple reading

Previously planned PDF support has been removed to focus on core functionality.

### Testing Strategy

- Use `flutter test` for unit and widget tests
- Test files are located in the `test/` directory
- Follow Flutter testing best practices for widget testing

## Important Considerations

### Target User Base

This app is specifically designed for users with ADHD and reading difficulties. When making UI/UX changes:

- Maintain clean, distraction-free interfaces
- Ensure large, accessible touch targets
- Preserve high contrast ratios
- Keep navigation simple and intuitive

### Platform Optimization

While the app supports multiple platforms, iOS is the primary target. Ensure:

- iOS-specific UI patterns are followed
- Cupertino design elements are used where appropriate
- Platform-specific capabilities are leveraged

### Performance Requirements

- Cold startup time: < 3 seconds
- File conversion: < 5 seconds for 1MB files
- Memory usage: < 200MB
- Optimized for battery usage

## Future Development Areas

The PRD and specifications mention upcoming features:
- Cloud sync for reading progress
- Multiple file format support
- Reading analytics and insights
- Voice-to-text integration
- Social reading features

When implementing new features, refer to the detailed specifications in `PRD.md` and `UI_SPECIFICATION.md` for comprehensive requirements and design guidelines.