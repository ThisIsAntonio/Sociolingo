# Chat project in Flutter and API in Node.js
Note: This is a College project for the class Project1.

This is a project in development that uses Flutter to create a chat application and an API in Node.js for database management. Currently, the project includes the following features:

- User registration and authentication using Firebase Auth.
- Real-time chat functionality.
- Chat windows to talk between users in real time.
- AI system to help translate languages if needed
- User status updates (Online/Offline).
- Notifications for new messages using Firebase Cloud Messaging (FCM).
- Data storage and real-time updates with Firestore.
- User profile and settings.
- Friend List.
- Multilanguage (the app can switch between English, Spanish and French).

## Initial setup

To start developing this project, follow these steps:

### Flutter Application Configuration

1. Clone the Flutter app repository:
https://github.com/ThisIsAntonio/Project1.git

2. Navigate to the Flutter application directory:
cd Project1/chat_app

3. Install Flutter dependencies:
flutter pub get

4. Optional: Check problems with old versions:
flutter pub outdated

5. Run the Flutter app:
flutter run

Note:
If you want to create an APK to later Install it follow these commands:
  
    a. flutter build apk --release (to create an Android version)
  
    b. flutter build ios --release (to create an IOS version)

To install it:
    
  1. Android use:
      flutter install apk
  2. IOS:
      
        1. Open Xcode: Open the generated iOS project within your Flutter project. This is located in <your_flutter_project>/ios/Runner.xcworkspace.
      
        2. Connect Your iOS Device: Connect your iOS device to your computer using a USB cable.
      
        3. Select Your Device in Xcode: In Xcode's toolbar, select your iOS device from the dropdown menu of available devices.
      
        4. Code Signing the App: Before you can install your app on a device, you need to configure code signing. Go to Project > Runner > Signing & Capabilities and make sure you have selected a team under the "Team" section. 
          If you're developing for personal use, you can select your Apple ID account as your team.
      
        5. Install the App on the Device: With your device selected and code signing configured, you can install the app directly from Xcode. Click the play button (▶️) on the toolbar in Xcode or select Product > Run from the menu bar. 
          Xcode will compile the app and install it on your device.

  Note: Remember that to install apps directly on iOS devices, you need an Apple developer account. If you're using a free account, there are limitations, such as needing to manually reinstall your app every 7 days.

## Firebase Configuration
Ensure you have set up a Firebase project and linked it with your Flutter app. Follow the Firebase documentation to add Firebase to your Flutter project: https://firebase.flutter.dev/docs/overview

## Database and Authentication Setup
- Use Firebase Console to create authentication providers (Email/Password, Google, etc.).
- Set up Firestore database rules for secure data access.
- Configure Cloud Functions for server-side logic, like sending notifications.

## Important Updates
- Migration from a local Node.js server and SQL database to Firebase for more streamlined development and real-time features.
- Introduction of real-time status updates and message notifications to enhance user experience.
- Enhanced security and ease of development using Firebase's suite of tools.
- Added chat between users in real time and Online/Offline status.
- The app works now in IOS.
- Some updates in the SizeScreens.

## Artificial Intelligence

The backend server uses openAI, and does API calls for language translation.
An openAI API key is required to use the Language translation system.
-API Key need to be able to call upon the model: gpt-3.5-turbo-0125

## License

This project does not have a specific license for now. Be aware of the licenses of the dependencies you use and make sure you comply with them.

Enjoy working on your chat project in Flutter and Node.js on Project1!
