# 🔐 Keeper

> Because remembering API tokens is so last season.

[![Version](https://img.shields.io/badge/version-0.3.0-blue.svg)](https://github.com/lloydculpepper/keeper)
[![Flutter](https://img.shields.io/badge/flutter-3.6.0+-46D1FD.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 🚀 Overview

**Keeper** is a minimalist, programmer-friendly macOS menu bar utility for managing API tokens. It securely stores your tokens, handles automatic refreshing, and seamlessly integrates with Git repositories.

```dart
if (you.hate(managing_tokens)) {
  keeper.solve(your_problems);
}
```

## ✨ Features

- **🔒 Secure Token Storage**: Keep your API tokens safe and organized
- **🔄 Automatic Token Refreshing**: Never deal with expired tokens again
- **🖥️ Menu Bar Integration**: Quick access without cluttering your workspace
- **🌙 Multiple Theme Support**: Including classic terminal themes like Solarized, Monokai, Dracula, and Nord
- **🔌 Git Repository Integration**: Automatically configure Git repositories with your tokens
- **👤 Service-specific Usernames**: Maintain different identities for different services
- **♿ Accessibility Features**: High contrast UI elements and semantic labels

## 🛠️ Technical Details

### Architecture

Keeper is built with Flutter and follows a clean, modular architecture:

- **Models**: Data structures for tokens, repositories, and settings
- **Services**: Business logic for token management, Git integration, and settings
- **UI**: Minimal, programmer-oriented interface with accessibility features

### Token Management

Tokens are stored locally with the following properties:
- Name, service type, and value
- Expiration date
- Associated repositories
- Refresh history

### Supported Services

- GitLab
- GitHub
- (More coming soon!)

### Theme Support

Keeper includes several classic terminal color schemes:
- Default (Light/Dark)
- Solarized (Light/Dark)
- Monokai
- Dracula
- Nord

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/lloydculpepper/keeper.git

# Navigate to the project directory
cd keeper

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🧩 Usage

### Adding a Token

1. Click the Keeper icon in your menu bar
2. Click the "+" button
3. Select the service type
4. Enter your token details
5. Click "Save"

### Linking a Git Repository

1. Open a token's details
2. Click "Add" in the Repositories section
3. Select your Git repository folder
4. Keeper will automatically configure the repository to use your token

### Changing Themes

1. Click the settings icon
2. Select your preferred theme mode (Light/Dark/System)
3. Choose a color palette from the available options

## 🧪 Development

### Prerequisites

- Flutter SDK 3.6.0+
- Dart 3.0.0+
- macOS 10.15+

### Building from Source

```bash
# Build the macOS app
flutter build macos

# The built app will be in build/macos/Build/Products/Release/
```

### Project Structure

```
lib/
├── main.dart              # Application entry point
├── models/               # Data models
│   ├── settings.dart     # App settings model
│   └── token.dart        # Token and repository models
├── services/             # Business logic
│   ├── git_service.dart  # Git repository integration
│   ├── service_factory.dart  # Service implementations
│   ├── settings_service.dart # Settings management
│   ├── theme_service.dart    # Theme management
│   └── token_storage.dart    # Token persistence
├── ui/                   # User interface
│   ├── app_window.dart   # Main application window
│   ├── common/           # Shared UI components
│   ├── settings_page.dart # Settings screen
│   └── token_details_page.dart # Token details screen
└── utils/               # Utility functions
    └── token_formatter.dart # Token formatting utilities
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

```dart
// How to contribute
if (you.have(new_feature) || you.found(bug)) {
  fork();
  fix();
  pull_request();
  // No promises, but we'll try to merge it faster than a token expires!
}
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) - For making cross-platform development less painful than token management
- [window_manager](https://pub.dev/packages/window_manager) - For window management that doesn't make you pull your hair out
- [tray_manager](https://pub.dev/packages/tray_manager) - For menu bar integration that actually works

## 💖 Support

If you find this project helpful, consider buying me a coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/opvlmakesthings)

---

<p align="center">Made with ❤️ and probably too much caffeine</p>
<p align="center">
  <img src="https://media.giphy.com/media/13HgwGsXF0aiGY/giphy.gif" width="300" alt="Programming GIF">
</p>