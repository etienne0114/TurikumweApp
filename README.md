# turikumwe_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Turikumwe - Community Connection App

Turikumwe is a Flutter mobile application designed to unite Rwandans by connecting people across districts and backgrounds. The app enables users to join groups, share ideas, and collaborate on community projects that drive positive change. With real-time chat, event updates, and inspiring stories, Turikumwe fosters a space where Rwandans can support and uplift each other.

## Features

- **User Authentication**: Email/password and Google sign-in
- **User Profiles**: Personalized profiles with district information and interests
- **Home Feed**: Community posts and updates
- **Groups**: Join and participate in community groups
- **Events**: Discover and RSVP for local events
- **Messaging**: Real-time chat with users and groups
- **Stories/Impact**: Share success and unity stories
- **Notifications**: Stay updated with important alerts

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging
  - Analytics

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / VS Code
- Firebase account
- Node.js and npm (for Firebase CLI)

### Setup Instructions

1. **Clone the repository**

```bash
git clone https://github.com/your-username/turikumwe.git
cd turikumwe
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase Setup**

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Create a Firebase project
# Visit https://console.firebase.google.com/ and create a new project named "Turikumwe"

# Configure Firebase for your app
flutterfire configure --project=[your-firebase-project-id]
```

4. **Enable Firebase Services**

- Authentication: Email/Password and Google Sign-in
- Firestore Database: Create in production mode
- Storage: Set up with appropriate rules
- Cloud Messaging: Configure for notifications

5. **Firestore Rules Setup**

Copy the Firestore rules from the Firebase configuration file to your Firebase console.

6. **Run the app**

```bash
flutter run
```

## Project Structure

```
turikumwe/
├── android/             # Android native code
├── ios/                 # iOS native code
├── lib/                 # Dart source code
│   ├── config/          # App configuration
│   ├── core/            # Core utilities and services
│   ├── data/            # Data layer (models, providers, repositories)
│   ├── presentation/    # UI layer (screens, widgets)
│   ├── app.dart         # App widget
│   └── main.dart        # Entry point
├── pubspec.yaml         # Project dependencies
└── README.md            # Project documentation
```

## Key Components

### Data Layer

- **Models**: Define the structure of app data
- **Providers**: Manage app state with ChangeNotifier
- **Repositories**: Handle data operations and Firebase interaction

### Presentation Layer

- **Screens**: Main