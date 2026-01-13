# 💰 MoneyMind AI

A modern Flutter application that combines financial tracking with AI-powered insights to help users understand and improve their financial wellness. MoneyMind uses machine learning and behavioral analysis to calculate your Financial Stress Index and provide personalized financial advice.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/license-MIT-blue)

## ✨ Features

### 📊 Financial Stress Index
- Real-time calculation of your financial stress level (0-100)
- Risk level assessment (Low, Medium, High)
- Money personality analysis (Avoider, Worrier, Stress-Spender, Balanced)
- Predictive risk window detection

### 💸 Expense Tracking
- Add and categorize expenses
- Track planned vs. unplanned spending
- Real-time updates to financial metrics

### 📈 Analytics & Insights
- **Daily, Monthly, and Yearly Analytics**: Visual bar charts showing spending patterns over time
- Spending pattern analysis
- Financial feature summaries
- Recent mood and spending history

### 🤖 AI-Powered Assistant
- Chat with Google Gemini AI for personalized financial advice
- Generate custom budgets based on your spending patterns
- Get explanations for spending behaviors
- Quick action buttons for common queries

### 😊 Mood Tracking
- Daily check-ins to track emotional state
- Correlation between mood and spending patterns
- Identify emotional triggers for spending

### 🎨 Modern Dark UI
- Professional dark theme with indigo/purple accents
- Minimal and modern design
- Smooth animations and transitions
- Material 3 design system

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.10+
- **Backend**: Firebase
  - Authentication (Firebase Auth)
  - Database (Cloud Firestore)
  - Cloud Functions (for stress index calculation)
- **AI**: Google Gemini Pro API
- **Visualization**: fl_chart
- **State Management**: StreamBuilder, FutureBuilder
- **Storage**: SharedPreferences

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Firebase CLI
- Node.js (for Cloud Functions)
- Android Studio / Xcode (for mobile development)
- A Google account for Firebase and Gemini API

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/SloppyTank9892/MoneyMind.git
cd MoneyMind
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create a Firestore database
4. Download `google-services.json` for Android and place it in `android/app/`
5. Download `GoogleService-Info.plist` for iOS and place it in `ios/Runner/`
6. Update `firestore.rules` with your security rules

### 4. Configure API Keys

1. Get your Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create or update `lib/config/api_keys.dart`:

```dart
class ApiKeys {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
}
```

**Note**: This file is already in `.gitignore` to keep your keys secure.

### 5. Setup Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 6. Run the App

```bash
flutter run
```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── login.dart                # Authentication screen
├── dashboard.dart            # Main dashboard with stress index
├── checkin.dart              # Daily mood check-in
├── spend.dart                # Add expense screen
├── ai.dart                   # AI chat interface
├── models/                   # Data models
│   ├── user_profile.dart
│   ├── financial_features.dart
│   ├── mood_entry.dart
│   ├── spending_entry.dart
│   └── chat_message.dart
├── screens/                  # Feature screens
│   ├── onboarding_screen.dart
│   ├── analytics_screen.dart
│   ├── insights_screen.dart
│   └── admin_dashboard.dart
└── services/                 # Business logic
    ├── firestore_service.dart
    └── gemini_service.dart
```

## 🔧 Configuration

### Firestore Security Rules

The app uses Firestore security rules to protect user data. Make sure your rules allow:
- Authenticated users to read/write their own data
- Cloud Functions to read/write user data

### Cloud Functions

The app includes two Cloud Functions:
- `dailyStressEngine`: Scheduled function that calculates stress index daily
- `recalculateStressIndex`: Callable function for real-time updates

## 📊 Features in Detail

### Financial Stress Index Calculation

The stress index is calculated using:
- Recent spending patterns (last 7 days)
- Mood entries and emotional state
- Spending frequency and amounts
- Planned vs. unplanned spending ratio
- Recency weighting (more recent data has higher impact)

### AI Chat Features

- **Budget Generation**: Creates personalized budgets based on your spending history
- **Spending Analysis**: Explains why you might be overspending
- **Financial Advice**: Provides actionable tips to improve financial wellness
- **Context-Aware**: Uses your financial data to provide relevant suggestions

## 🎨 UI/UX Design

- **Dark Theme**: Professional dark color scheme with `#121212` background
- **Color Palette**: Indigo (`#6366F1`) and Purple (`#8B5CF6`) accents
- **Typography**: Modern, readable fonts with proper spacing
- **Animations**: Smooth transitions and hero animations
- **Accessibility**: Material 3 design guidelines

## 📝 Environment Variables

The following files should be configured (and are in `.gitignore`):
- `lib/config/api_keys.dart` - API keys
- `android/app/google-services.json` - Firebase Android config
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [Google Gemini](https://deepmind.google/technologies/gemini/) - AI capabilities
- [fl_chart](https://github.com/imaNNeoFighT/fl_chart) - Beautiful charts

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

**Made with ❤️ using Flutter**
