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
 * and later execute this to check the code errors
 * inside the function folder
 * npm run lint -- --fix
 * to finaly run again the firebase deploy commands
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const OpenAI = require("openai");
admin.initializeApp();

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

/**
 * Function to send push notification when new user is created
 */
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
  console.log("=============> " + payload);

  // send message
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

// Function to translate text from one language to another
exports.translateTextFunction = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      // Throwing an HTTP error if the user is not authenticated.
      throw new functions.https.HttpsError("unauthenticated",
        "The function must be called while authenticated.");
    }

    const {text, fromLanguage, toLanguage} = data;
    // const translatedText = `Translated from ${fromLanguage}
    // to ${toLanguage}: ${text}`;
    // console.log(translatedText);
    try {
      const translatedText = await charlie(fromLanguage, toLanguage, text);
      // console.log("=====> Return: " + translatedText);
      return {translatedText: translatedText};
    } catch (error) {
      console.error("Error during translation:", error);
      throw new functions.https.HttpsError("unknown",
        "Failed to translate text",
        error);
    }
  });


/**
* Charlie when called upon will translate one language to another.
* It is not perfect, but it is good enough for our purposes.
* @param {string} baseLang The language of the message
* @param {string} transLang The language the message must be translated to
* @param {string} msg The message to be translated
* @return {Promise<Object>} The translated message
*/
async function charlie(baseLang, transLang, msg) {
  // Thought you'd love the name 😉
  const completion = await openai.chat.completions.create({
    messages: [{role: "system", content: "You are an expert" +
    "language translator." +
    "You are skilled in translating " + baseLang + " to " + transLang +
    " and correcting any grammatical errors." +
    " When translating an Eastern language you are to " +
    "translate using the most formal form. " +
    "Also when responding you will ONLY respond with the translation."},
    {"role": "user", "content": "Translate: " + msg + " From " +
    baseLang + " to " + transLang + "."}],
    model: "gpt-3.5-turbo",
  });

  // Returns a large nasty JSON file.
  // This will grab only the response we want
  const charlieAnswer = completion.choices[0].message;
  // console.log(charlieAnswer["content"]);

  return charlieAnswer["content"];
}
