# PondStat Mobile App

PondStat is a comprehensive mobile application built with Flutter, designed to help aquaculture farmers efficiently manage and monitor their ponds. Whether you are farming Shrimp or Tilapia, PondStat provides the tools you need to track growth, monitor water quality parameters, manage daily operations, and analyze financial performance.

## 🌟 Key Features

*   **Dashboard:** Get a quick overview of all your active ponds, current culture periods, and high-level statistics.
*   **Pond Management:** Create, edit, and manage individual ponds or groups with specific stocking quantities, target culture periods, and species tracking.
*   **Parameter Monitoring:** Log and track essential water quality parameters (e.g., pH, temperature, dissolved oxygen) to ensure optimal conditions.
*   **Growth Tracking:** Record physical measurements to track the growth curve of your stock over time.
*   **Operations & Finances:** Log daily operations, feed consumption, and track expenses to maintain profitability.
*   **Authentication:** Secure user accounts managed via Firebase Authentication.

## 🛠 Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend:** [Firebase](https://firebase.google.com/)
    *   Firestore (Database)
    *   Firebase Auth (Authentication)
    *   Firebase Storage (Media/Assets)
*   **Local Storage:** Shared Preferences
*   **Architecture:** Feature-based folder structure with separation of concerns (Presentation, Domain, Data layers).

## 📁 Project Structure

The project follows a clean, feature-centric directory structure inside the `lib/` folder:

```text
lib/
├── core/                   # Shared resources, widgets, themes, and network/firebase helpers
│   ├── error/
│   ├── firebase/
│   ├── network/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/            # Reusable UI components (e.g., PondStatTextField, PondStatDropdownField)
├── features/               # Main application features
│   ├── auth/               # User authentication and onboarding
│   ├── dashboard/          # Main landing view and pond summaries
│   ├── monitoring/         # Detailed tracking for parameters, growth, and finances
│   └── profile/            # User settings and profile management
└── main.dart               # Application entry point
```

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure it's up to date)
*   An IDE like [Android Studio](https://developer.android.com/studio), [IntelliJ IDEA](https://www.jetbrains.com/idea/), or [VS Code](https://code.visualstudio.com/) with Flutter plugins installed.
*   A connected physical device or emulator (iOS/Android)

### Installation

1.  **Clone the repository**
    ```sh
    git clone https://github.com/your-username/PondStat-Mobile-App.git
    cd PondStat-Mobile-App
    ```

2.  **Install dependencies**
    ```sh
    flutter pub get
    ```

3.  **Firebase Configuration**
    This project requires Firebase to function. 
    *   Create a project in the [Firebase Console](https://console.firebase.google.com/).
    *   Enable Firestore, Authentication, and Storage.
    *   Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to configure the app for your Firebase project:
        ```sh
        dart pub global activate flutterfire_cli
        flutterfire configure
        ```
    *   This will generate the necessary `firebase_options.dart` and native configuration files.

4.  **Run the application**
    ```sh
    flutter run
    ```

## 🧪 Testing

The project includes widget and unit tests to ensure UI reliability and correct business logic. 

To run the test suite:
```sh
flutter test
```

## 🎨 Theming & Styling

PondStat utilizes Material 3 theming heavily. The application defines a comprehensive `ThemeData` object in `lib/core/theme/app_theme.dart` with custom color schemes and typography (Google Fonts).

Core UI widgets (like `PondStatTextField` and `PondStatDropdownField`) are built to automatically inherit from the active `ThemeData` to ensure seamless transitions between Light and Dark modes.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
