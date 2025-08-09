# MatFixer - Flutter Frontend Application

This Flutter application serves as the user interface for the MatFixer AI-Powered MATLAB Troubleshooter. It provides a chat interface for users to interact with the backend agents, manage conversations, and provide feedback.

## Features

* **Chat Interface:** Utilizes the `flutter_ai_toolkit` package (`LlmChatView`) for a familiar chat UI.
* **Backend Integration:** Connects to FastAPI backends (`Backend1` and `Backend2`) to send queries and receive generated responses/reports.
* **Agent Switching:** Allows users to switch between different backend agents/configurations ("Agent 1" likely points to Backend2, "Agent 1 Advanced" likely points to Backend1) via a dropdown in the sidebar.
* **Conversation Management:**
  * Displays a list of past conversations in a collapsible sidebar.
  * Allows creating new conversations, renaming existing ones, and deleting conversations.
  * Persists conversations using Firebase Firestore.
* **Feedback System:** Users can submit feedback on conversations (including whether the problem was resolved and a text comment), which is saved to Firestore.
* **Admin Dashboard:** A separate view (`/admin/dashboard`) for authenticated admin users to view submitted feedback.
* **User Authentication:** Supports anonymous sign-in for general users and email/password authentication for admins via Firebase Auth.
* **MATLAB Integration Guide:** Includes a screen (`InstallationGuideScreen`) showing steps to integrate the troubleshooting capabilities directly into a user's MATLAB environment using provided `.m` and `.py` scripts.
* **Theming:** Supports both light and dark themes, styled similarly to MATLAB's interface colors (`MatlabAppTheme`, `MatlabChatTheme`).

## Architecture

* **UI:** Built with Flutter framework. Uses `Provider` for state management (like theme) and `flutter_ai_toolkit` for the core chat UI.
* **State Management:** Primarily uses `StatefulWidget` and `ValueNotifier` for local UI state. `ChangeNotifier` is used within the `FastApiLlmProvider`.
* **Backend Communication:** Uses the `http` package to make POST requests to the FastAPI backends defined in `lib/providers/fast_api_llm_provider.dart`.
  * `Agent 1` points to `http://<backend_ip>:8002` (Likely `Backend2`).
  * `Agent 1 Advanced` points to `http://<backend_ip>:8000` (Likely `Backend1`).
* **Persistence:** Uses Firebase Firestore (`cloud_firestore`) to save and stream user conversations and submitted feedback.
* **Authentication:** Uses Firebase Authentication (`firebase_auth`) for anonymous and email/password sign-in. `AuthService` handles authentication logic and admin checks.

## Setup

1. **Install Flutter:** Ensure you have the Flutter SDK installed. See the [Flutter installation guide](https://docs.flutter.dev/get-started/install).
2. **Clone Repository:** Clone this project.
3. **Get Dependencies:** Navigate to the `app` directory and run:

    ```bash
    flutter pub get
    ```

4. **Firebase Setup:**
    * Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/).
    * Enable **Authentication** (Anonymous and Email/Password providers).
    * Enable **Firestore Database**. Set up Firestore security rules appropriately (e.g., allow authenticated users to read/write their own conversations/feedback).
    * Configure your Flutter app for Firebase using the FlutterFire CLI: `flutterfire configure`. This will generate/update `lib/firebase_options.dart` and platform-specific configuration files (like `macos/Runner/GoogleService-Info.plist`).
5. **Backend URLs:** Verify the backend URLs in `lib/providers/fast_api_llm_provider.dart` point to the correct IP address and ports where your `Backend1` and `Backend2` services are running. Use `localhost` or your local network IP.

## Running

1. **Ensure Backends are Running:** Start `Backend1` (port 8000) and `Backend2` (port 8002) as described in their respective READMEs.
2. **Run Flutter App:** Connect a device or start an emulator/simulator. Then run:

    ```bash
    flutter run -d <windows|macos|chrome>
    ```

    *(Select the desired target platform)*

## Key Packages

* `flutter_ai_toolkit`: Provides the core `LlmChatView` widget and provider abstractions.
* `firebase_core`, `firebase_auth`, `cloud_firestore`: Firebase integration.
* `http`: For making API calls to backends.
* `provider`: Simple state management.
* `google_fonts`: For custom fonts.
* `flutter_markdown`: For rendering Markdown responses from the backend.
* `shared_preferences`: Used for potentially storing settings (though API key storage seems removed).
* `uuid`: For generating unique conversation IDs.
* `intl`: For date/time formatting.
