# Chat project in Flutter and API in Node.js
Note: This is a College project for the class Project1.

This is a project in development that uses Flutter to create a chat application and an API in Node.js for database management. Currently, the project includes the following features:

- User registration screen.
- Login screen.
- Node.js API for database management.

## Initial setup

To start developing this project, follow these steps:

### Flutter Application Configuration

1. Clone the Flutter app repository:
https://github.com/ThisIsAntonio/Project1.git

2. Navigate to the Flutter application directory:
cd Project1/chat_app

3. Install Flutter dependencies:
flutter pub get

3.1 Optional: Check problems with old versions:
flutter pub outdated

5. Run the Flutter app:
flutter run

Note:
  If you want to create an APK to later Install it follow these commands:
    a. flutter build apk --release (to create an Android version)
    b. flutter build ios --release (to create an IOS version)

  To install it:
    a. Android use:
      flutter install apk
    b. IOS:
      i. Open Xcode: Open the generated iOS project within your Flutter project. This is located in <your_flutter_project>/ios/Runner.xcworkspace.
      ii. Connect Your iOS Device: Connect your iOS device to your computer using a USB cable.
      iii. Select Your Device in Xcode: In Xcode's toolbar, select your iOS device from the dropdown menu of available devices.
      iv. Code Signing the App: Before you can install your app on a device, you need to configure code signing. Go to Project > Runner > Signing & Capabilities and make sure you have selected a team under the "Team" section. 
          If you're developing for personal use, you can select your Apple ID account as your team.
      v. Install the App on the Device: With your device selected and code signing configured, you can install the app directly from Xcode. Click the play button (▶️) on the toolbar in Xcode or select Product > Run from the menu bar. 
          Xcode will compile the app and install it on your device.

      Note: Remember that to install apps directly on iOS devices, you need an Apple developer account. If you're using a free account, there are limitations, such as needing to manually reinstall your app every 7 days.

### API configuration in Node.js

The API in Node.js is designed to manage the database of the application. Make sure the API code is located in the "Project1/node-api" directory. Then, configure the API by following these steps:

1. Clone the API repository:
https://github.com/ThisIsAntonio/Project1.git

2. Navigate to the API directory in Node.js:
cd Project1/mysql_conn

3. Install Node.js dependencies:
npm install

4. Run the Node js application
node server.js

note: right now, I've deployed a node server to check how works the app, however, if you need to modify the server.js file, you need to change the url for login, register, user info, modify user info by the localhost url.

### SQL files:

There is an example of the DBA working on my own server, if you want to use your own, please feel free to do it, however, check the .sql file because this has all the first tables to start this interesting project.

## License

This project does not have a specific license for now. Be aware of the licenses of the dependencies you use and make sure you comply with them.

Enjoy working on your chat project in Flutter and Node.js on Project1!


