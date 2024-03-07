/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at
 * https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/**
 * After modify this document, you need to do a deploit.
 * please use this comand to do it in command prompt :
 * firebase deploy --only functions
 * now, if you have problems with the code,
 * please use this to install the package
 * npm install eslint --save-dev
 *  and later execute this to check the code errors
 * npm run lint -- --fix
 * to finaly run again the firebase deploy commands
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushNotification = functions.https.onCall((data, context) => {
  // Check if the user is logged in
  if (!context.auth) {
    throw new functions.https.HttpsError("failed-precondition",
      "The function must be called while authenticated.");
  }

  const message = data.message;
  const token = data.token;
  const title = data.title;
  const senderName = data.senderName;

  const payload = {
    notification: {
      title: title,
      body: senderName + ": " + message,
    },
    data: {
      type: title,
      senderName: senderName,
    },
    token: token,
  };

  return admin.messaging().send(payload)
    .then((response) => {
      console.log("Successfully sent message:", response);
      return {success: true};
    })
    .catch((error) => {
      console.log("Error sending message:", error);
      throw new functions.https.HttpsError("unknown",
        "Failed to send push notification", error);
    });
});
