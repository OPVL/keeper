# Keeper - API Token Manager

A macOS menu bar utility for managing API tokens, built with Flutter.

## Features

- Securely store and manage API tokens
- Display token validity status
- Refresh expired tokens
- Support for GitLab tokens (expandable to other services)
- Menu bar integration for quick access
- Configurable service settings (base URLs, etc.)

## Getting Started

### Prerequisites

- Flutter SDK (3.6.0 or higher)
- Dart SDK (3.6.0 or higher)
- macOS development environment

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/keeper.git
   cd keeper
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run -d macos
   ```

## Configuration

### Service Settings

You can configure the base URLs for different services in the Settings page:

1. Click on the settings icon in the app or select "Settings" from the menu bar
2. Expand a service to see its settings
3. Update the base URL to match your instance (e.g., https://gitlab.example.com)
4. Toggle services on/off as needed

## Architecture

The application is structured as follows:

- **models/**: Data models for API tokens and settings
- **services/**: Service classes for API integration and token storage
- **ui/**: User interface components

## Adding New Services

To add support for a new API service:

1. Create a new service class in `lib/services/`
2. Add the service to the `ServiceType` enum in `service_factory.dart`
3. Register the service in the `AppSettings.defaults()` method
4. Implement the necessary methods for token validation and creation

## License

This project is licensed under the MIT License - see the LICENSE file for details