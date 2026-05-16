# PondStat Mobile App

PondStat is a comprehensive mobile application built with Flutter, designed to help aquaculture farmers transition from paper logs to efficient digital management. 

## 🎯 Primary Purpose & Target Audience
**The Problem:** Aquaculture farming requires rigorous daily tracking of water quality, feed, and growth. Paper logs are prone to loss, make historical analysis difficult, and delay critical interventions.
**The Solution:** PondStat digitizes farm operations.
**Intended User:** Shrimp and Tilapia farmers, farm managers, and aquaculture technicians who need real-time data input and analysis at the pond edge.

## 🌟 Core Features (Top 5)
1. **Real-time Parameter Monitoring:** Log essential water quality parameters (pH, DO, temperature, salinity) with visual alerts for out-of-range metrics.
2. **Biometric Growth Tracking:** Record sampling data to visualize growth curves and estimate total biomass.
3. **Feed & Inventory Management:** Log daily feed consumption to calculate Feed Conversion Ratio (FCR) and track expenses.
4. **Offline Support:** Local caching allows data entry at remote ponds without internet, syncing automatically when connectivity is restored.
5. **Role-Based Access Control:** Differentiate access between Farm Owners (full edit/delete) and Technicians (data entry only).

## 📄 Requirements & Specifications
*   **Target Platforms:** iOS 14.0+ and Android API 24+ (Mobile only; tablets supported but not optimized).
*   *For detailed feature specifications and design documents, please refer to the `docs/specs/` directory.*

## 🚫 Known Limitations & Out-of-Scope Features
*   **No Hardware Integration:** Currently does not integrate directly with IoT water quality sensors; all data entry is manual.
*   **Species Limitations:** Specifically calibrated for Shrimp and Tilapia; other species can be logged but lack tailored growth curve predictions.
*   **Web/Desktop:** Not currently optimized or supported for Web or Desktop deployment.

## 🛠 Tech Stack & Environment Constraints

*   **Framework:** [Flutter](https://flutter.dev/) (Requires Flutter SDK 3.19.0 or higher)
*   **Language:** Dart 3.3+
*   **Backend:** [Firebase](https://firebase.google.com/) (Firestore, Auth, Storage, Cloud Functions)
*   **Cloud Functions Node Version:** Requires Node.js 18+ (see `functions/package.json`)

## 📁 Project Structure

The project follows a clean, feature-centric directory structure inside the `lib/` folder:

```text
lib/
├── core/                   # Shared resources, widgets, themes, and network/firebase helpers
├── features/               # Main application features (auth, dashboard, monitoring, profile)
└── main.dart               # Application entry point
```

## 🚀 Setup & Run Instructions

### Prerequisites
1.  Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0+)
2.  Install [Node.js](https://nodejs.org/) (v18+) for Firebase Functions deployment.
3.  Install the [Firebase CLI](https://firebase.google.com/docs/cli) and login.

### Installation
1.  **Clone the repository**
    ```sh
    git clone https://github.com/your-username/PondStat-Mobile-App.git
    cd PondStat-Mobile-App
    ```

2.  **Install Flutter dependencies**
    ```sh
    flutter pub get
    ```

3.  **Firebase Configuration**
    This project requires a Firebase project to function.
    *   Create a project in the [Firebase Console](https://console.firebase.google.com/).
    *   Enable Firestore, Authentication (Email/Password), Storage, and Firebase Cloud Messaging.
    *   Initialize FlutterFire:
        ```sh
        dart pub global activate flutterfire_cli
        flutterfire configure
        ```
    *   Deploy Cloud Functions (Optional, for notifications/aggregations):
        ```sh
        cd functions
        npm install
        npm run build
        firebase deploy --only functions
        ```

4.  **Run the application**
    ```sh
    flutter run
    ```

## 🔑 Test Credentials & Sample Data
To test the application without setting up your own Firebase instance immediately, you can use the following read-only test account (assuming the provided Firebase project is connected):
*   **Email:** `demo@pondstat.app`
*   **Password:** `DemoTest123!`
*(Note: To test owner-level destructive actions, you must create a new account).*

## ⚠️ Risky Operations & Data Deletion
*   **Pond Deletion:** Deleting a Pond (via the Dashboard swipe action) is a **cascading, permanent deletion**. It will immediately erase the pond document and trigger a background function to delete all associated sub-collections (measurements, feed logs, finances). This cannot be undone.
*   **Account Deletion:** Users deleting their account will immediately lose access, and their user record will be purged.

## 🛡️ Error Handling Expectations
*   **Network Loss:** If the device loses internet connection, the UI will display a banner indicating offline status. Write operations (like logging a measurement) will be cached locally by Firestore and synced automatically upon reconnection.
*   **Permission Denied:** If a user attempts an action outside their role (e.g., a viewer trying to edit a pond), a standardized UI `EmptyStateCard` or Snackbar will display "You don't have permission to view/edit this data."
*   **Server Errors:** Unhandled backend exceptions are caught by global error handlers and displayed as user-friendly Snackbar messages, while the raw stack trace is logged to `dart:developer` for debugging.

## 🤝 Contributing
Contributions are welcome. Please ensure you run `flutter analyze` and `flutter test` before submitting pull requests.