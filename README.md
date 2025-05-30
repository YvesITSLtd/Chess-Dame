# Rwanda Fun Facts

A new fun way to fall in love with Rwanda through an interactive AI-powered mobile application.

## 🌟 Features

- **Interactive AI Chat**: Ask questions about Rwanda and get intelligent responses
- **Curated Facts**: Discover interesting facts about Rwanda's culture, history, and wildlife
- **Beautiful UI**: Modern, clean interface with Rwanda-inspired design
- **Offline Fallbacks**: Pre-defined responses when API calls fail
- **Conversation History**: Maintains context across chat sessions

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- A Google AI (Gemini) API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Chess-Dame
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit the `.env` file and add your API keys:
   ```env
   GEMINI_API_KEY=your_actual_gemini_api_key_here
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔐 API Security Setup

### Getting Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the key to your `.env` file

### Security Best Practices

#### ✅ What We've Implemented

- **Environment Variables**: API keys are stored in `.env` files, not hardcoded
- **Git Ignore**: `.env` files are excluded from version control
- **Fallback Responses**: App works even when API calls fail
- **Input Validation**: API key presence is validated before making calls
- **Error Handling**: Graceful degradation when API services are unavailable

#### 🔒 Security Features

- **No Hardcoded Secrets**: All sensitive data is externalized
- **Runtime Validation**: API key validity is checked at runtime
- **Secure Storage**: Uses Flutter's secure storage mechanisms
- **Production Ready**: Environment-based configuration for different deployment stages

#### ⚠️ Important Security Notes

1. **Never commit `.env` files** - They're in `.gitignore` for a reason
2. **Use different API keys** for development, staging, and production
3. **Regularly rotate your API keys** for better security
4. **Monitor API usage** to detect unusual activity
5. **Implement rate limiting** in production environments

### Environment File Structure

Create a `.env` file in your project root:

```env
# Gemini API Configuration
GEMINI_API_KEY=your_api_key_here

# Optional: Add other environment-specific configurations
# APP_ENV=development
# API_TIMEOUT=30
# MAX_RETRIES=3
```

### Production Deployment

For production deployments:

1. **Use CI/CD Environment Variables**: Don't include `.env` files in production builds
2. **Use Cloud Secret Managers**: AWS Secrets Manager, Google Secret Manager, etc.
3. **Implement API Key Rotation**: Regular key updates with zero downtime
4. **Monitor and Alert**: Set up monitoring for API failures and unusual usage

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point with environment loading
├── models/
│   └── fact.dart            # Data models
├── screens/
│   ├── home_screen.dart     # Main navigation
│   ├── facts_screen.dart    # Curated facts display
│   ├── ask_screen.dart      # AI chat interface
│   └── about_screen.dart    # App information
└── services/
    └── ai_service.dart      # Secure AI API integration
```

## 🛠️ Development

### Running in Debug Mode

```bash
flutter run --debug
```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass
5. Submit a pull request

### Development Guidelines

- Follow Flutter's style guidelines
- Add tests for new features
- Update documentation for API changes
- Never commit sensitive information
- Use meaningful commit messages

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Troubleshooting

### Common Issues

**API Key Not Working**
- Verify your API key in the `.env` file
- Check Google AI Studio for key restrictions
- Ensure the key has proper permissions

**App Crashes on Startup**
- Check if `.env` file exists
- Verify environment variable loading in `main.dart`
- Check Flutter and Dart SDK versions

**Build Failures**
- Run `flutter clean` and `flutter pub get`
- Check for platform-specific issues
- Verify all dependencies are compatible

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check existing documentation
- Review the troubleshooting section

## 🙏 Acknowledgments

- Google AI for Gemini API
- Flutter team for the amazing framework
- Rwanda tourism board for inspiration
- All contributors to this project
