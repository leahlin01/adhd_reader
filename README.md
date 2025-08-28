# ADHD Reader - iOS App

A Flutter-based iOS application designed specifically for people with ADHD to improve their reading experience through innovative techniques like Bionic Reading.

## Features

### 🏠 Home Page

- Welcome message and reading statistics
- Recent reading books with progress tracking
- Quick action buttons for importing books and continuing reading
- Reading statistics (daily, weekly, total books)

### 📚 Library Page

- Search functionality for books
- Book list with progress bars
- Import new books (PDF, EPUB, TXT)
- Book management (continue reading, settings, delete)

### 📖 Reader Page

- **Bionic Reading** - First few letters of each word are bolded for faster recognition
- Adjustable font size and line height
- Page navigation with swipe gestures
- Bookmark functionality
- Table of contents
- Reader settings

### ⚙️ Settings Page

- Reading preferences (font size, line height, margins)
- Theme settings (light/dark mode, background colors)
- Font family selection
- Bionic reading intensity control
- Data export and app information

## Design Principles

- **Simplified Interface**: Clean, distraction-free design
- **High Contrast**: Ensures text readability
- **Large Touch Targets**: Easy navigation for ADHD users
- **Consistent Design Language**: Unified visual hierarchy
- **Accessibility**: Screen reader support and keyboard navigation

## Color Scheme

- **Primary**: #2563EB (Blue) - Represents focus and trust
- **Secondary**: #10B981 (Green) - Success and progress
- **Accent**: #F59E0B (Orange) - Important information and alerts
- **Light Theme**: White backgrounds with dark text
- **Dark Theme**: Dark backgrounds with light text

## Typography

- **Primary Font**: Inter (sans-serif, optimized for screen reading)
- **Fallback**: SF Pro Display (iOS), Roboto (Android)
- **Reading Text**: 18px default, adjustable 14px-24px
- **Line Height**: 1.6 for reading content, 1.5 for UI text

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- iOS development tools (Xcode)
- iOS Simulator or physical iOS device

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/adhd_reader.git
cd adhd_reader
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

### Building for iOS

1. Ensure you have a valid iOS development certificate
2. Build the app:

```bash
flutter build ios
```

3. Open the generated `.xcworkspace` file in Xcode
4. Configure signing and build settings
5. Build and run on device or simulator

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Theme configuration
├── pages/
│   ├── home_page.dart       # Home page
│   ├── library_page.dart    # Library page
│   ├── reader_page.dart     # Reader page
│   └── settings_page.dart   # Settings page
└── widgets/
    └── common_widgets.dart  # Reusable components
```

## Key Components

### Bionic Reading Implementation

The app implements Bionic Reading by making the first 40% of each word bold, helping the brain recognize words faster and maintain focus.

### Responsive Design

- Adapts to different screen sizes
- Optimized for iOS devices
- Supports both portrait and landscape orientations

### State Management

- Uses Flutter's built-in StatefulWidget for local state
- Efficient state updates with setState
- Proper disposal of controllers and listeners

## Future Enhancements

- [ ] Cloud sync for reading progress
- [ ] Multiple file format support (PDF, EPUB, TXT)
- [ ] Reading analytics and insights
- [ ] Customizable reading themes
- [ ] Social reading features
- [ ] Offline reading support
- [ ] Voice-to-text integration
- [ ] Reading speed tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Email: support@adhdreader.com
- GitHub Issues: [Create an issue](https://github.com/yourusername/adhd_reader/issues)

## Acknowledgments

- Flutter team for the amazing framework
- Bionic Reading technique developers
- ADHD community for feedback and insights
- Open source contributors

---

**Note**: This app is designed specifically for people with ADHD but can benefit anyone looking to improve their reading focus and speed.
