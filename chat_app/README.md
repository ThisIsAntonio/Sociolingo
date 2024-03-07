# Sociolingo Project

This is a Flutter project developed to create a full-featured chat application. It leverages Firebase for authentication, real-time database interactions, notifications, and more.

## Getting Started

This project serves as an advanced template for a Flutter-based chat application integrated with Firebase. Whether you're new to Flutter or an experienced developer, this project offers a practical example of building a more complex application.

## Prerequisites
Before diving into the project, make sure you have the following set up:

* Flutter installed on your machine. If you haven't installed Flutter yet, follow the official installation guide.
* An IDE with Flutter support (e.g., Android Studio, VS Code).
* A Firebase project set up and linked to your Flutter app. Check out the Firebase for Flutter codelab for guidance.

## Project Setup
1. Clone the repository:
git clone https://github.com/ThisIsAntonio/Project1.git

2. Navigate to the project directory:
cd chat_app

3. Install dependencies:
flutter pub get

4. Create your Firebase project and download the google-services.json (for Android) or GoogleService-Info.plist (for iOS) file. Place it in the appropriate directory (android/app or ios/Runner).

## Running the Project
* To run the project in debug mode:
flutter run

* To build a release APK for Android:
flutter build apk --release

* To build a release IPA for iOS:
flutter build ios --release

Note: Building for iOS requires a macOS system with Xcode installed.

## Features
- User registration and authentication using Firebase Auth.
- Real-time chat functionality.
- Chat windows to talk between users in real time.
- User status updates (Online/Offline).
- Notifications for new messages using Firebase Cloud Messaging (FCM).
- Data storage and real-time updates with Firestore.
- User profile and settings.
- Friend List.
- Multilanguage (the app can switch between English, Spanish and French).

## Resources
For more information on Flutter development, refer to the following resources:

* Flutter Documentation - Comprehensive guides, tutorials, and API reference.
* Firebase Flutter Codelab - A hands-on tutorial for integrating Firebase with a Flutter app.
* Flutter Cookbook - Practical recipes for common Flutter tasks.
* Happy coding, and enjoy building your chat app with Flutter and Firebase!