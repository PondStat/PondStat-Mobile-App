<div align="center">
  <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" alt="Flutter Logo" width="100"/>
  <h1>PondStat Mobile App</h1>
  <p><strong>A comprehensive mobile application designed to help aquaculture farmers transition from paper logs to efficient digital management.</strong></p>

  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase" alt="Firebase"></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/Riverpod-%231A237E.svg?style=for-the-badge&logo=flutter&logoColor=white" alt="Riverpod"></a>
  </p>
</div>

---

## 🎯 The Vision

> [!IMPORTANT]  
> **Academic Use Only**: This application is strictly restricted to **F125 takers of the Fisheries course in UP Visayas (UPV)**. Sign-in uses Google OAuth, and **only users with a valid `@up.edu.ph` email address are accepted**.

**The Problem:** Aquaculture farming requires rigorous daily tracking of water quality, feed, and growth. Paper logs are prone to loss, make historical analysis difficult, and delay critical interventions.

**The Solution:** PondStat digitizes farm operations, allowing Shrimp and Tilapia farmers, farm managers, and aquaculture technicians to input and analyze real-time data directly at the pond edge.

## ✨ Key Features

- 💧 **Real-time Parameter Monitoring**: Log essential water quality parameters (pH, DO, temperature, salinity) with visual alerts for out-of-range metrics.
- 📈 **Biometric Growth Tracking**: Record sampling data to visualize growth curves and estimate total biomass.
- 💰 **Feed & Inventory Management**: Log daily feed consumption to calculate Feed Conversion Ratio (FCR) and track expenses.
- 📶 **Offline Support**: Local caching allows data entry at remote ponds without internet, syncing automatically when connectivity is restored.
- 🔐 **Role-Based Access Control**: Differentiate access between Farm Owners (full edit/delete) and Technicians (data entry only).

## 🏛 Architecture

PondStat is built following clean architecture principles, heavily relying on **Riverpod** for robust, testable Dependency Injection and State Management.

- **DI First**: All repositories and services are accessed via Riverpod providers (`ref.read` / `ref.watch`).
- **Feature-first Structure**: Code is organized by feature rather than layer, enhancing modularity and scalability.

```text
lib/
├── core/                   # Shared resources, widgets, themes, and network/firebase helpers
├── features/               # Main application features
│   ├── auth/               # Authentication & User Management
│   ├── dashboard/          # Pond Overview & High-level metrics
│   ├── monitoring/         # Water Quality, Growth, Feed, & Expenses
│   └── profile/            # User settings & configuration
└── main.dart               # Application entry point
```

## 🛠 Tech Stack & Requirements

- **Framework:** [Flutter SDK](https://flutter.dev/) (v3.19.0+)
- **Language:** Dart 3.3+
- **State Management:** [Riverpod](https://riverpod.dev/) (v3.3+)
- **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Auth, Storage, Cloud Functions)
- **Target Platforms:** iOS 14.0+ and Android API 24+

*Note: The app is currently optimized for mobile. Tablets are supported but not fully optimized. Web/Desktop deployment is currently out-of-scope.*

## 🚀 Getting Started

### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Install [Node.js](https://nodejs.org/) (v18+) for Firebase Functions deployment.
3. Install the [Firebase CLI](https://firebase.google.com/docs/cli) and login.

### Installation

1. **Clone the repository**
   ```sh
   git clone https://github.com/your-username/PondStat-Mobile-App.git
   cd PondStat-Mobile-App
   ```

2. **Install Flutter dependencies**
   ```sh
   flutter pub get
   ```

3. **Firebase Configuration**
   This project requires a Firebase project to function.
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Enable **Firestore**, **Authentication** (Email/Password), **Storage**, and **Firebase Cloud Messaging**.
   - Initialize FlutterFire:
     ```sh
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
   - Deploy Cloud Functions (Optional, for notifications/aggregations):
     ```sh
     cd functions
     npm install
     npm run build
     firebase deploy --only functions
     ```

4. **Run the application**
   ```sh
   flutter run
   ```

## 🔑 Demo Access

To test the application without setting up your own Firebase instance immediately, you can use the following read-only test account (assuming the provided Firebase project is connected and email/password auth is enabled for testing purposes):

- **Email:** `demo@up.edu.ph`
- **Password:** `DemoTest123!`

*(Note: To test owner-level destructive actions, you must create a new account).*

## 🛡️ Error Handling, Reliability & Security

### Reliability
- **Offline First**: If the device loses internet connection, the UI will display an offline banner. Write operations (like logging a measurement) are cached locally by Firestore and synced automatically upon reconnection.
- **Cascading Deletes**: Deleting a Pond (via the Dashboard swipe action) is a **cascading, permanent deletion**. It triggers a background function to delete all associated sub-collections (measurements, feed logs, finances).

### Security
- **Backend Email Restrictions**: The `firestore.rules` are configured to explicitly reject any API requests where the authenticated user's email does not match `*@up.edu.ph`. Even if an attacker obtains a valid Firebase Auth token via a personal Gmail account, the database will categorically deny read/write access.
- **Role-Based Access Control**: Standard UI `EmptyStateCard`s or Snackbars enforce permissions. Backend rules strictly validate document modifications against `roles` arrays.
- **API Key Hardening (Recommended)**: For production deployment, you must restrict the Firebase API keys found in your `google-services.json` and `GoogleService-Info.plist`. In the Google Cloud Console, add **Application Restrictions** (Android apps/iOS apps) to prevent quota theft.
- **Firebase App Check**: To further secure backend functions and Firestore from unauthorized clients, it is highly recommended to enable **Firebase App Check** using Play Integrity (Android) and DeviceCheck (iOS).
- **Code Obfuscation**: Always build the app using the provided obfuscation scripts (`build_prod.sh` or `build_prod.bat`) to scramble the Dart source code and protect intellectual property.

## 🤝 Contributing

We welcome contributions to PondStat! Before submitting pull requests, please ensure:
1. You run `flutter analyze` to catch syntax or formatting issues.
2. You run `flutter test` to ensure no existing tests are broken.
3. You follow the Riverpod DI patterns established in the codebase.

## 📄 License

This project is licensed under the MIT License.